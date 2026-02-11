import 'package:flutter/foundation.dart';
import '../models/asset_model.dart';
import 'supabase_service.dart';
import 'profile_service.dart';

class AssetService {
  static const String _tableName = 'assets';

  // Fetch all assets stream
  static Stream<List<AssetModel>> getAssetsStream({String? filter}) {
    dynamic query = SupabaseService.client.from(_tableName).stream(primaryKey: ['id']);
    
    if (filter != null && filter != 'All Assets') {
      // Note: supbabase_flutter streams have limited filtering capabilities compared to select().
      // Simple eq filters are supported.
      String statusFilter;
      switch (filter) {
        case 'In Stock':
          statusFilter = 'in_stock';
          break;
        case 'Assigned':
          statusFilter = 'assigned';
          break;
        case 'Repair':
          statusFilter = 'repair';
          break;
        default:
          statusFilter = '';
      }
      if (statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }
    }
    
    return (query.order('created_at', ascending: false) as Stream<List<Map<String, dynamic>>>).map<List<AssetModel>>((list) => 
      list.map((json) => AssetModel.fromJson(json)).toList()
    );
  }

  // Fetch assets by location stream
  static Stream<List<AssetModel>> getAssetsByLocationStream(String locationId) {
    return SupabaseService.client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('location_id', locationId)
        .order('created_at', ascending: false)
        .map<List<AssetModel>>((list) => 
          list.map((json) => AssetModel.fromJson(json)).toList()
        );
  }

  // Fetch all assets (Future - Kept for reference or specific use cases)
  static Future<List<AssetModel>> getAssets({String? filter}) async {
    try {
      var query = SupabaseService.client.from(_tableName).select();
      
      if (filter != null && filter != 'All Assets') {
        String statusFilter;
        switch (filter) {
          case 'In Stock':
            statusFilter = 'in_stock';
            break;
          case 'Assigned':
            statusFilter = 'assigned';
            break;
          case 'Repair':
            statusFilter = 'repair';
            break;
          default:
            statusFilter = '';
        }
        if (statusFilter.isNotEmpty) {
          query = query.eq('status', statusFilter);
        }
      }
      
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => AssetModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching assets: $e');
      return [];
    }
  }

  // Fetch asset by ID
  static Future<AssetModel?> getAssetById(String id) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return AssetModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching asset by ID: $e');
      return null;
    }
  }

  // Add new asset
  static Future<AssetModel> addAsset(AssetModel asset) async {
    // 1. Get current user's profile to find their company_id
    final profile = await ProfileService.getCurrentProfile();
    
    // Use provided companyId (from dropdown) or fallback to user's company
    // If both are null, we might have an issue, but let's proceed and let DB constraint fail if needed
    final String? companyId = asset.companyId ?? profile?['company_id'];
    
    if (companyId == null) {
       throw Exception('Company ID is required');
    }

    // 2. Add asset with company_id
    final assetJson = asset.toJson();
    assetJson['company_id'] = companyId;

    final response = await SupabaseService.client
        .from(_tableName)
        .insert(assetJson)
        .select()
        .single();
    
    // Update accessories if present
    if (asset.status == AssetStatus.assigned && asset.assignedTo != null) {
      if (asset.mouseSerial != null) await _updateAccessoryStatus(asset.mouseSerial!, asset.assignedTo, companyId);
      if (asset.headsetSerial != null) await _updateAccessoryStatus(asset.headsetSerial!, asset.assignedTo, companyId);
    }

    return AssetModel.fromJson(response);
  }

  // Update asset
  static Future<void> updateAsset(AssetModel asset) async {
    await SupabaseService.client
        .from(_tableName)
        .update(asset.toJson())
        .eq('id', asset.id);

    // Update accessories if present
    if (asset.status == AssetStatus.assigned && asset.assignedTo != null) {
      if (asset.mouseSerial != null) await _updateAccessoryStatus(asset.mouseSerial!, asset.assignedTo, asset.companyId);
      if (asset.headsetSerial != null) await _updateAccessoryStatus(asset.headsetSerial!, asset.assignedTo, asset.companyId);
    } else if (asset.status == AssetStatus.inStock) {
      if (asset.mouseSerial != null) await _updateAccessoryStatus(asset.mouseSerial!, null, asset.companyId);
      if (asset.headsetSerial != null) await _updateAccessoryStatus(asset.headsetSerial!, null, asset.companyId);
    }
  }

  // Delete asset
  static Future<void> deleteAsset(String id) async {
    await SupabaseService.client
        .from(_tableName)
        .delete()
        .eq('id', id);
  }

  // Helper to update accessory status by serial
  static Future<void> _updateAccessoryStatus(String serial, String? assignedTo, String? companyId) async {
    if (serial.isEmpty) return;

    try {
      // Find asset by serial (and company if possible, though serial should be unique)
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('serial_number', serial)
          .maybeSingle();

      if (response != null) {
        final accessoryId = response['id'];
        
        // Update status to assigned/in_stock based on assignedTo
        final newStatus = assignedTo != null ? 'assigned' : 'in_stock';
        
        await SupabaseService.client.from(_tableName).update({
          'status': newStatus,
          'assigned_to': assignedTo,
          // We don't necessarily change company_id, it should already match
        }).eq('id', accessoryId);
      }
    } catch (e) {
      debugPrint('Error updating accessory $serial: $e');
    }
  }
}
