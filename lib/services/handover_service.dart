import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/profile_service.dart';
import '../services/asset_service.dart';
import '../models/handover_model.dart';
import '../models/asset_model.dart';
import 'package:uuid/uuid.dart';

/// Service for managing asset handovers
class HandoverService {
  static const String _tableName = 'handovers';
  static const String _bucketName = 'signatures';

  /// Create a new handover record
  static Future<HandoverModel> createHandover({
    required String assetId,
    required String toUserId,
    required String toUserName,
    Uint8List? issuerSignature,
    Uint8List? recipientSignature,
    String? notes,
    String? pdfUrl,
  }) async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) {
        throw Exception('User not authenticated');
      }

      final handoverId = const Uuid().v4();
      String? issuerSigUrl;
      String? recipientSigUrl;

      // Upload issuer signature if provided
      if (issuerSignature != null) {
        final issuerPath = 'handovers/$handoverId/issuer_signature.png';
        await SupabaseService.client.storage
            .from(_bucketName)
            .uploadBinary(issuerPath, issuerSignature);
        issuerSigUrl = SupabaseService.client.storage
            .from(_bucketName)
            .getPublicUrl(issuerPath);
      }

      // Upload recipient signature if provided
      if (recipientSignature != null) {
        final recipientPath = 'handovers/$handoverId/recipient_signature.png';
        await SupabaseService.client.storage
            .from(_bucketName)
            .uploadBinary(recipientPath, recipientSignature);
        recipientSigUrl = SupabaseService.client.storage
            .from(_bucketName)
            .getPublicUrl(recipientPath);
      }

      // Get asset details
      final asset = await AssetService.getAssetById(assetId);

      // Create handover record
      final handoverData = {
        'id': handoverId,
        'asset_id': assetId,
        'asset_name': asset?.name,
        'from_user_id': profile['id'],
        'from_user_name': profile['full_name'] ?? profile['email'],
        'to_user_id': toUserId,
        'to_user_name': toUserName,
        'issuer_signature_url': issuerSigUrl,
        'recipient_signature_url': recipientSigUrl,
        'notes': notes,
        'pdf_url': pdfUrl,
        'company_id': profile['company_id'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client.from(_tableName).insert(handoverData);

      // Update asset assignment
      if (asset != null) {
        final updatedAsset = asset.copyWith(
          assignedTo: toUserName,
          status: AssetStatus.assigned,
          lastHandoverDate: DateTime.now(),
          custodyDocumentUrl: pdfUrl,
        );
        await AssetService.updateAsset(updatedAsset);
      }

      return HandoverModel.fromJson(handoverData);
    } catch (e) {
      debugPrint('Error creating handover: $e');
      rethrow;
    }
  }

  /// Get handover history for an asset
  static Future<List<HandoverModel>> getHandoverHistory(
      String assetId) async {
    try {
      final data = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('asset_id', assetId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => HandoverModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching handover history: $e');
      return [];
    }
  }

  /// Get handover history stream for an asset
  static Stream<List<HandoverModel>> getHandoverHistoryStream(String assetId) {
    return SupabaseService.client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('asset_id', assetId)
        .order('created_at', ascending: false)
        .map((list) =>
            list.map((json) => HandoverModel.fromJson(json)).toList());
  }

  /// Get recent handovers for the company
  static Stream<List<HandoverModel>> getRecentHandoversStream() {
    return Stream.fromFuture(
      ProfileService.getCurrentProfile(),
    ).asyncExpand<List<HandoverModel>>((profile) {
      if (profile == null) {
        return Stream<List<HandoverModel>>.value(<HandoverModel>[]);
      }

      final companyId = profile['company_id'];

      return SupabaseService.client
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('company_id', companyId)
          .order('created_at', ascending: false)
          .limit(50)
          .map((list) =>
              list.map((json) => HandoverModel.fromJson(json)).toList());
    }).asBroadcastStream();
  }

  /// Upload PDF to storage
  static Future<String> uploadPdf(
      String handoverId, Uint8List pdfBytes) async {
    try {
      final path = 'handovers/$handoverId/custody_certificate.pdf';
      await SupabaseService.client.storage
          .from('pdfs')
          .uploadBinary(path, pdfBytes);

      return SupabaseService.client.storage.from('pdfs').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading PDF: $e');
      rethrow;
    }
  }
}
