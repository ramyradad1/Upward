import 'package:flutter/foundation.dart';
import '../models/request_model.dart';
import 'supabase_service.dart';
import 'profile_service.dart';
import 'notification_service.dart';

class RequestService {
  static const String _tableName = 'requests_approvals';

  /// Create a new request
  static Future<RequestModel?> createRequest({
    required RequestType type,
    String? assetId,
    String? assetName,
    String? fromLocationId,
    String? toLocationId,
    String? notes,
  }) async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return null;

      final userId = profile['id'];
      final userName = profile['name'] ?? profile['email'] ?? 'Unknown';
      final companyId = profile['company_id'];

      final data = {
        'requester_id': userId,
        'requester_name': userName,
        'type': RequestModel.typeToString(type),
        'status': 'pending',
        'asset_id': assetId,
        'asset_name': assetName,
        'from_location_id': fromLocationId,
        'to_location_id': toLocationId,
        'notes': notes,
        'company_id': companyId,
      };

      final response = await SupabaseService.client
          .from(_tableName)
          .insert(data)
          .select()
          .single();

      // Notify admins about new request
      await NotificationService.createNotification(
        userId: userId,
        title: 'New Request Created',
        body: '${RequestModel.typeDisplayName(type)} request submitted by $userName',
        type: 'request_created',
        referenceId: response['id'],
      );

      return RequestModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating request: $e');
      throw 'Failed to create request: $e';
    }
  }

  /// Approve a request
  static Future<bool> approveRequest(String requestId) async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return false;

      final approverName = profile['name'] ?? profile['email'] ?? 'Unknown';

      await SupabaseService.client
          .from(_tableName)
          .update({
            'status': 'approved',
            'approver_id': profile['id'],
            'approver_name': approverName,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      // Get the request to notify the requester
      final request = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', requestId)
          .single();

      await NotificationService.createNotification(
        userId: request['requester_id'],
        title: 'Request Approved ✅',
        body: 'Your ${request['type']?.replaceAll('_', ' ')} request was approved by $approverName',
        type: 'request_approved',
        referenceId: requestId,
      );

      return true;
    } catch (e) {
      debugPrint('Error approving request: $e');
      return false;
    }
  }

  /// Reject a request
  static Future<bool> rejectRequest(String requestId, {String? reason}) async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return false;

      final approverName = profile['name'] ?? profile['email'] ?? 'Unknown';

      await SupabaseService.client
          .from(_tableName)
          .update({
            'status': 'rejected',
            'approver_id': profile['id'],
            'approver_name': approverName,
            'reject_reason': reason,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      // Get the request to notify the requester
      final request = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', requestId)
          .single();

      await NotificationService.createNotification(
        userId: request['requester_id'],
        title: 'Request Rejected ❌',
        body: 'Your ${request['type']?.replaceAll('_', ' ')} request was rejected${reason != null ? ': $reason' : ''}',
        type: 'request_rejected',
        referenceId: requestId,
      );

      return true;
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      return false;
    }
  }

  /// Stream of the current user's requests
  static Stream<List<RequestModel>> getMyRequestsStream() {
    return Stream.fromFuture(
      ProfileService.getCurrentProfile(),
    ).asyncExpand<List<RequestModel>>((profile) {
      if (profile == null) {
        return Stream<List<RequestModel>>.value(<RequestModel>[]);
      }

      return SupabaseService.client
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('requester_id', profile['id'])
          .order('created_at', ascending: false)
          .map((list) => list.map((json) => RequestModel.fromJson(json)).toList());
    }).asBroadcastStream();
  }

  /// Stream of pending approvals (for managers/admins)
  static Stream<List<RequestModel>> getPendingApprovalsStream() {
    return Stream.fromFuture(
      ProfileService.getCurrentProfile(),
    ).asyncExpand<List<RequestModel>>((profile) {
      if (profile == null) {
        return Stream<List<RequestModel>>.value(<RequestModel>[]);
      }

      final companyId = profile['company_id'];

      return SupabaseService.client
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('company_id', companyId)
          .order('created_at', ascending: false)
          .map((list) => list
              .map((json) => RequestModel.fromJson(json))
              .where((r) => r.status == RequestStatus.pending)
              .toList());
    }).asBroadcastStream();
  }

  /// Stream of all requests for the company
  static Stream<List<RequestModel>> getAllRequestsStream() {
    return Stream.fromFuture(
      ProfileService.getCurrentProfile(),
    ).asyncExpand<List<RequestModel>>((profile) {
      if (profile == null) {
        return Stream<List<RequestModel>>.value(<RequestModel>[]);
      }

      final companyId = profile['company_id'];

      return SupabaseService.client
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('company_id', companyId)
          .order('created_at', ascending: false)
          .map((list) => list.map((json) => RequestModel.fromJson(json)).toList());
    }).asBroadcastStream();
  }

  /// Get pending requests count
  static Future<int> getPendingCount() async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return 0;

      final response = await SupabaseService.client
          .from(_tableName)
          .select('id')
          .eq('company_id', profile['company_id'])
          .eq('status', 'pending');

      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting pending count: $e');
      return 0;
    }
  }
}
