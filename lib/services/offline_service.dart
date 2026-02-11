import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/asset_model.dart';
import '../models/location_model.dart';
import 'supabase_service.dart';
import 'connectivity_service.dart';

class OfflineService {
  static const String _assetsBoxName = 'assets_cache';
  static const String _locationsBoxName = 'locations_cache';
  static const String _pendingOpsBoxName = 'pending_ops';

  static late Box _assetsBox;
  static late Box _locationsBox;
  static late Box _pendingOpsBox;
  
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    
    _assetsBox = await Hive.openBox(_assetsBoxName);
    _locationsBox = await Hive.openBox(_locationsBoxName);
    _pendingOpsBox = await Hive.openBox(_pendingOpsBoxName);

    _isInitialized = true;
    
    // Listen for connectivity changes to trigger sync
    ConnectivityService().connectionStream.listen((isOnline) {
      if (isOnline) {
        syncPendingOperations();
      }
    });
  }

  // --- Caching Methods ---

  static Future<void> cacheAssets(List<AssetModel> assets) async {
    if (!_isInitialized) return;
    await _assetsBox.clear();
    final Map<String, dynamic> data = {
      for (var a in assets) a.id: jsonEncode(a.toJson())
    };
    await _assetsBox.putAll(data);
    debugPrint('Cached ${assets.length} assets');
  }

  static List<AssetModel> getCachedAssets() {
    if (!_isInitialized) return [];
    try {
      return _assetsBox.values
          .map((json) => AssetModel.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error reading cached assets: $e');
      return [];
    }
  }

  static Future<void> cacheLocations(List<LocationModel> locations) async {
    if (!_isInitialized) return;
    await _locationsBox.clear();
    final Map<String, dynamic> data = {
      for (var l in locations) l.id: jsonEncode(l.toJson()) // LocationModel needs toJson/fromJson fix if ID not included
    };
    await _locationsBox.putAll(data);
    debugPrint('Cached ${locations.length} locations');
  }
  
  static List<LocationModel> getCachedLocations() {
    if (!_isInitialized) return [];
    try {
      return _locationsBox.values
          .map((json) {
            final Map<String, dynamic> data = jsonDecode(json);
             // Verify ID is present in JSON, if not, we can't fully reconstruct properly without key
             // But for now assuming standard serialization
            return LocationModel.fromJson(data);
          })
          .toList();
    } catch (e) {
      debugPrint('Error reading cached locations: $e');
      return [];
    }
  }
  
  // --- Operation Queueing ---

  static Future<void> queueOperation({
    required String table,
    required String type, // 'insert', 'update', 'delete'
    required Map<String, dynamic> data,
    String? id, // Required for update/delete
  }) async {
    if (!_isInitialized) return;
    
    final op = {
      'table': table,
      'type': type,
      'data': data,
      'id': id,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _pendingOpsBox.add(jsonEncode(op));
    debugPrint('Queued $type operation for $table');
  }

  static Future<void> syncPendingOperations() async {
    if (!_isInitialized || _pendingOpsBox.isEmpty) return;
    if (!ConnectivityService().isOnline) return;

    debugPrint('Syncing ${_pendingOpsBox.length} pending operations...');
    
    final keysToDelete = <dynamic>[];

    for (var i = 0; i < _pendingOpsBox.length; i++) {
      final key = _pendingOpsBox.keyAt(i);
      final String jsonStr = _pendingOpsBox.getAt(i);
      final op = jsonDecode(jsonStr);
      
      bool success = false;
      try {
        switch (op['type']) {
          case 'insert':
            await SupabaseService.client
                .from(op['table'])
                .insert(op['data']);
            success = true;
            break;
            
          case 'update':
            if (op['id'] != null) {
              await SupabaseService.client
                  .from(op['table'])
                  .update(op['data'])
                  .eq('id', op['id']);
              success = true;
            }
            break;
            
          case 'delete':
            if (op['id'] != null) {
              await SupabaseService.client
                  .from(op['table'])
                  .delete()
                  .eq('id', op['id']);
              success = true;
            }
            break;
        }
      } catch (e) {
        debugPrint('Sync failed for op $i: $e');
        // Keep in queue if it's a network error, remove if logic error? 
        // For now, simpler to leave in queue and retry later, or implement max retries.
      }

      if (success) {
        keysToDelete.add(key);
      }
    }
    
    if (keysToDelete.isNotEmpty) {
      await _pendingOpsBox.deleteAll(keysToDelete);
      debugPrint('Synced & removed ${keysToDelete.length} operations');
    }
  }
  
  static int get pendingCount => _isInitialized ? _pendingOpsBox.length : 0;
}
