import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/audit_session_model.dart';
import 'supabase_service.dart';

class AuditService {
  static final _supabase = SupabaseService.client;
  static const _table = 'audit_sessions';

  /// Create a new audit session for a location
  static Future<AuditSessionModel?> createSession({
    required String locationId,
    required String locationName,
    String? performedBy,
  }) async {
    try {
      final session = AuditSessionModel(
        id: const Uuid().v4(),
        locationId: locationId,
        locationName: locationName,
        performedBy: performedBy ?? _supabase.auth.currentUser?.email,
        createdAt: DateTime.now(),
      );

      final response = await _supabase
          .from(_table)
          .insert(session.toJson())
          .select()
          .single();

      return AuditSessionModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating audit session: $e');
      return null;
    }
  }

  /// Scan a serial number and match against assets at the session's location
  static Future<ScannedItem> processScannedItem({
    required String sessionId,
    required AuditSessionModel session,
    required String serialNumber,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Look up asset by serial number
      final assetResponse = await _supabase
          .from('assets')
          .select()
          .eq('serial_number', serialNumber)
          .maybeSingle();

      ScanResult result;
      String? assetName;

      if (assetResponse == null) {
        // Asset not found in database at all
        result = ScanResult.unknown;
      } else {
        assetName = assetResponse['name'];
        final assetLocationId = assetResponse['location_id'];

        if (assetLocationId == session.locationId) {
          result = ScanResult.matched;
        } else {
          result = ScanResult.misplaced;
        }

        // Update asset's last seen coordinates
        if (latitude != null && longitude != null) {
          await _supabase.from('assets').update({
            'last_seen_lat': latitude,
            'last_seen_lng': longitude,
            'last_seen_at': DateTime.now().toIso8601String(),
          }).eq('id', assetResponse['id']);
        }
      }

      final item = ScannedItem(
        serialNumber: serialNumber,
        assetName: assetName,
        result: result,
        scannedAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
      );

      // Update session with new scanned item
      final updatedItems = [...session.scannedItems, item];
      await _supabase.from(_table).update({
        'scanned_items': updatedItems.map((e) => e.toJson()).toList(),
      }).eq('id', sessionId);

      return item;
    } catch (e) {
      debugPrint('Error processing scan: $e');
      return ScannedItem(
        serialNumber: serialNumber,
        result: ScanResult.unknown,
        scannedAt: DateTime.now(),
      );
    }
  }

  /// Complete an audit session — compute missing items
  static Future<AuditSessionModel?> completeSession(AuditSessionModel session) async {
    try {
      // Fetch all assets at this location
      List<String> missingSerials = [];
      if (session.locationId != null) {
        final locationAssets = await _supabase
            .from('assets')
            .select('serial_number')
            .eq('location_id', session.locationId!);

        final scannedSerials = session.scannedItems.map((i) => i.serialNumber).toSet();
        missingSerials = (locationAssets as List)
            .map((a) => a['serial_number'] as String)
            .where((s) => !scannedSerials.contains(s))
            .toList();
      }

      await _supabase.from(_table).update({
        'status': 'completed',
        'missing_items': missingSerials,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', session.id);

      return session.copyWith(
        status: AuditStatus.completed,
        missingItems: missingSerials,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error completing audit: $e');
      return null;
    }
  }

  /// Get all audit sessions (stream)
  static Stream<List<AuditSessionModel>> getAuditSessionsStream() {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map<List<AuditSessionModel>>((list) =>
          list.map((json) => AuditSessionModel.fromJson(json)).toList());
  }

  /// Get all audit sessions (future)
  static Future<List<AuditSessionModel>> getAuditSessions() async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AuditSessionModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching audits: $e');
      return [];
    }
  }

  /// Get single audit session by ID
  static Future<AuditSessionModel?> getSessionById(String id) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('id', id)
          .single();

      return AuditSessionModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching audit session: $e');
      return null;
    }
  }

  /// Delete an audit session
  static Future<bool> deleteSession(String id) async {
    try {
      await _supabase.from(_table).delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting audit: $e');
      return false;
    }
  }
}
