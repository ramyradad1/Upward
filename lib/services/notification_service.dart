import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'supabase_service.dart';
import 'profile_service.dart';

class NotificationService {
  static const String _tableName = 'notifications';

  /// Create a new notification
  static Future<void> createNotification({
    required String userId,
    required String title,
    String? body,
    String type = 'info',
    String? referenceId,
  }) async {
    try {
      await SupabaseService.client.from(_tableName).insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'reference_id': referenceId,
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Stream of notifications for the current user
  static Stream<List<NotificationModel>> getNotificationsStream() {
    return Stream.fromFuture(
      ProfileService.getCurrentProfile(),
    ).asyncExpand<List<NotificationModel>>((profile) {
      if (profile == null) {
        return Stream<List<NotificationModel>>.value(<NotificationModel>[]);
      }

      return SupabaseService.client
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('user_id', profile['id'])
          .order('created_at', ascending: false)
          .map((list) =>
              list.map((json) => NotificationModel.fromJson(json)).toList());
    }).asBroadcastStream();
  }

  /// Get unread count
  static Future<int> getUnreadCount() async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return 0;

      final response = await SupabaseService.client
          .from(_tableName)
          .select('id')
          .eq('user_id', profile['id'])
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllRead() async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return;

      await SupabaseService.client
          .from(_tableName)
          .update({'is_read': true})
          .eq('user_id', profile['id'])
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
