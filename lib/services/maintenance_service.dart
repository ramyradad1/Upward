import 'package:flutter/foundation.dart';
import '../models/maintenance_model.dart';
import 'supabase_service.dart';
import 'profile_service.dart';

/// Service for maintenance schedules & logs (Phase 6)
class MaintenanceService {
  static const String _schedulesTable = 'maintenance_schedules';
  static const String _logsTable = 'maintenance_logs';

  // ═══════════════════════════════════════════════════════════════
  // Schedules
  // ═══════════════════════════════════════════════════════════════

  /// Real-time stream of active maintenance schedules
  static Stream<List<MaintenanceSchedule>> getSchedulesStream() {
    return Stream.fromFuture(
      ProfileService.getCurrentProfile(),
    ).asyncExpand<List<MaintenanceSchedule>>((profile) {
      if (profile == null) {
        return Stream<List<MaintenanceSchedule>>.value(<MaintenanceSchedule>[]);
      }
      final companyId = profile['company_id'];

      return SupabaseService.client
          .from(_schedulesTable)
          .stream(primaryKey: ['id'])
          .eq('company_id', companyId)
          .order('next_due_date', ascending: true)
          .map((list) => list.map((e) => MaintenanceSchedule.fromJson(e)).toList());
    }).asBroadcastStream();
  }

  /// Get upcoming maintenance (due within N days)
  static Future<List<MaintenanceSchedule>> getUpcomingMaintenance({int daysAhead = 7}) async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return [];

      final companyId = profile['company_id'];
      final limit = DateTime.now().add(Duration(days: daysAhead)).toIso8601String();

      final response = await SupabaseService.client
          .from(_schedulesTable)
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .lte('next_due_date', limit)
          .order('next_due_date', ascending: true);

      return (response as List)
          .map((e) => MaintenanceSchedule.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching upcoming maintenance: $e');
      return [];
    }
  }

  /// Get overdue maintenance
  static Future<List<MaintenanceSchedule>> getOverdueMaintenance() async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return [];

      final companyId = profile['company_id'];
      final now = DateTime.now().toIso8601String();

      final response = await SupabaseService.client
          .from(_schedulesTable)
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .lt('next_due_date', now)
          .order('next_due_date', ascending: true);

      return (response as List)
          .map((e) => MaintenanceSchedule.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching overdue maintenance: $e');
      return [];
    }
  }

  /// Create a new maintenance schedule
  static Future<bool> createSchedule(MaintenanceSchedule schedule) async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return false;

      final data = schedule.toJson();
      data['company_id'] = profile['company_id'];
      data['created_by'] = profile['email'] ?? profile['name'];

      await SupabaseService.client.from(_schedulesTable).insert(data);
      return true;
    } catch (e) {
      debugPrint('Error creating maintenance schedule: $e');
      return false;
    }
  }

  /// Update an existing schedule
  static Future<bool> updateSchedule(String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await SupabaseService.client.from(_schedulesTable).update(updates).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error updating schedule: $e');
      return false;
    }
  }

  /// Delete a schedule
  static Future<bool> deleteSchedule(String id) async {
    try {
      await SupabaseService.client.from(_schedulesTable).delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
      return false;
    }
  }

  /// Calculate the next due date based on frequency
  static DateTime calculateNextDueDate(DateTime current, MaintenanceFrequency frequency) {
    switch (frequency) {
      case MaintenanceFrequency.daily:
        return current.add(const Duration(days: 1));
      case MaintenanceFrequency.weekly:
        return current.add(const Duration(days: 7));
      case MaintenanceFrequency.monthly:
        return DateTime(current.year, current.month + 1, current.day);
      case MaintenanceFrequency.quarterly:
        return DateTime(current.year, current.month + 3, current.day);
      case MaintenanceFrequency.semiAnnual:
        return DateTime(current.year, current.month + 6, current.day);
      case MaintenanceFrequency.annual:
        return DateTime(current.year + 1, current.month, current.day);
      case MaintenanceFrequency.oneTime:
        return current; // One-time doesn't recur
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Logs
  // ═══════════════════════════════════════════════════════════════

  /// Real-time stream of maintenance logs
  static Stream<List<MaintenanceLog>> getLogsStream() {
    return Stream.fromFuture(
      ProfileService.getCurrentProfile(),
    ).asyncExpand<List<MaintenanceLog>>((profile) {
      if (profile == null) {
        return Stream<List<MaintenanceLog>>.value(<MaintenanceLog>[]);
      }
      final companyId = profile['company_id'];

      return SupabaseService.client
          .from(_logsTable)
          .stream(primaryKey: ['id'])
          .eq('company_id', companyId)
          .order('performed_at', ascending: false)
          .map((list) => list.map((e) => MaintenanceLog.fromJson(e)).toList());
    }).asBroadcastStream();
  }

  /// Get logs for a specific asset
  static Future<List<MaintenanceLog>> getLogsForAsset(String assetId) async {
    try {
      final response = await SupabaseService.client
          .from(_logsTable)
          .select()
          .eq('asset_id', assetId)
          .order('performed_at', ascending: false);

      return (response as List)
          .map((e) => MaintenanceLog.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching logs for asset: $e');
      return [];
    }
  }

  /// Create a maintenance log entry and update the schedule
  static Future<bool> createLog(MaintenanceLog log, {String? scheduleId, MaintenanceFrequency? frequency}) async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return false;

      final data = log.toJson();
      data['company_id'] = profile['company_id'];

      await SupabaseService.client.from(_logsTable).insert(data);

      // If linked to a schedule, update the schedule's last_performed_at and next_due_date
      if (scheduleId != null && frequency != null) {
        final now = DateTime.now();
        final nextDue = calculateNextDueDate(now, frequency);
        await updateSchedule(scheduleId, {
          'last_performed_at': now.toIso8601String(),
          'next_due_date': nextDue.toIso8601String(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error creating maintenance log: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Statistics
  // ═══════════════════════════════════════════════════════════════

  /// Get maintenance statistics for analytics
  static Future<Map<String, dynamic>> getMaintenanceStats() async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return {};



      var schedQuery = SupabaseService.client
          .from(_schedulesTable)
          .select()
          .eq('is_active', true);
          
      var logsQuery = SupabaseService.client
          .from(_logsTable)
          .select();

      if (profile['company_id'] != null) {
        schedQuery = schedQuery.eq('company_id', profile['company_id']);
        logsQuery = logsQuery.eq('company_id', profile['company_id']);
      }

      final schedules = await schedQuery;
      final logs = await logsQuery;

      final scheduleList = schedules as List;
      final logList = logs as List;

      int overdue = 0;
      int dueSoon = 0;
      int onTrack = 0;
      double totalCost = 0;

      for (var s in scheduleList) {
        final nextDue = DateTime.tryParse(s['next_due_date'] ?? '');
        if (nextDue == null) continue;
        if (nextDue.isBefore(DateTime.now())) {
          overdue++;
        } else if (nextDue.difference(DateTime.now()).inDays <= 7) {
          dueSoon++;
        } else {
          onTrack++;
        }
      }

      for (var l in logList) {
        totalCost += (l['cost'] as num?)?.toDouble() ?? 0;
      }

      return {
        'total_schedules': scheduleList.length,
        'overdue': overdue,
        'due_soon': dueSoon,
        'on_track': onTrack,
        'total_logs': logList.length,
        'total_cost': totalCost,
      };
    } catch (e) {
      debugPrint('Error fetching maintenance stats: $e');
      return {};
    }
  }
}
