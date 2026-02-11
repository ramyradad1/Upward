import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/profile_service.dart';

/// Service for analytics and statistics
class AnalyticsService {
  static const String _assetsTable = 'assets';
  static const String _requestsTable = 'requests_approvals';

  /// Process assets to get status counts (Helper for testing)
  static Map<String, int> processStatusCounts(List<dynamic> assets) {
    final Map<String, int> statusCounts = {
      'available': 0,
      'in_use': 0,
      'maintenance': 0,
      'retired': 0,
    };

    for (var asset in assets) {
      final status = asset['status']?.toString() ?? 'available';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    return statusCounts;
  }

  /// Get asset count by status
  static Future<Map<String, int>> getAssetsByStatus({String? companyId}) async {
    try {
      final targetCompanyId =
          companyId ??
          (await ProfileService.getCurrentProfile())?['company_id'];
      
      var query = SupabaseService.client.from(_assetsTable).select('status');
      if (targetCompanyId != null) {
        query = query.eq('company_id', targetCompanyId);
      }

      final response = await query;
      return processStatusCounts(response as List);
    } catch (e) {
      debugPrint('Error fetching assets by status: $e');
      return {};
    }
  }

  /// Process assets to get category counts (Helper for testing)
  static Map<String, int> processCategoryCounts(List<dynamic> assets) {
    final Map<String, int> categoryCounts = {};

    for (var asset in assets) {
      final category = asset['category']?.toString() ?? 'Other';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }
    return categoryCounts;
  }

  /// Get asset count by category
  static Future<Map<String, int>> getAssetsByCategory({
    String? companyId,
  }) async {
    try {
      final targetCompanyId =
          companyId ??
          (await ProfileService.getCurrentProfile())?['company_id'];
      
      var query = SupabaseService.client.from(_assetsTable).select('category');
      if (targetCompanyId != null) {
        query = query.eq('company_id', targetCompanyId);
      }

      final response = await query;
      return processCategoryCounts(response as List);
    } catch (e) {
      debugPrint('Error fetching assets by category: $e');
      return {};
    }
  }

  /// Process requests to get stats (Helper for testing)
  static Map<String, int> processRequestStats(List<dynamic> requests) {
    final Map<String, int> stats = {
      'pending': 0,
      'approved': 0,
      'rejected': 0,
    };

    for (var request in requests) {
      final status = request['status']?.toString() ?? 'pending';
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  /// Get request statistics
  static Future<Map<String, int>> getRequestStats({String? companyId}) async {
    try {
      final targetCompanyId =
          companyId ??
          (await ProfileService.getCurrentProfile())?['company_id'];
      
      var query = SupabaseService.client.from(_requestsTable).select('status');
      if (targetCompanyId != null) {
        query = query.eq('company_id', targetCompanyId);
      }

      final response = await query;
      return processRequestStats(response as List);
    } catch (e) {
      debugPrint('Error fetching request stats: $e');
      return {'pending': 0, 'approved': 0, 'rejected': 0};
    }
  }

  /// Get total assets count
  static Future<int> getTotalAssets({String? companyId}) async {
    try {
      final targetCompanyId =
          companyId ??
          (await ProfileService.getCurrentProfile())?['company_id'];

      // Use count instead of fetching IDs if possible, but select('id') is lightweight enough for now
      // and safer if count isn't exposed directly in this helper without exact syntax.
      // Ideally: .count(CountOption.exact)
      
      var query = SupabaseService.client.from(_assetsTable).select('id');
      if (targetCompanyId != null) {
        query = query.eq('company_id', targetCompanyId);
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      debugPrint('Error fetching total assets: $e');
      return 0;
    }
  }
}
