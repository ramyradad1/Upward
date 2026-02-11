import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import 'supabase_service.dart';
import 'profile_service.dart';

class LocationService {
  static const String _tableName = 'locations';

  /// Stream all locations for the current user's company
  static Stream<List<LocationModel>> getLocationsStream() {
    return Stream.fromFuture(
      ProfileService.getCurrentProfile(),
    ).asyncExpand<List<LocationModel>>((profile) {
      if (profile == null) {
        return Stream<List<LocationModel>>.value(<LocationModel>[]);
      }

      final companyId = profile['company_id'];

      return SupabaseService.client
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('company_id', companyId)
          .order('name', ascending: true)
          .map((list) => list.map((json) => LocationModel.fromJson(json)).toList());
    }).asBroadcastStream();
  }

  /// Stream all locations (Super Admin)
  static Stream<List<LocationModel>> getAllLocationsStream() {
    return SupabaseService.client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((list) => list.map((json) => LocationModel.fromJson(json)).toList());
  }

  /// Stream locations for a specific company
  static Stream<List<LocationModel>> getLocationsByCompanyStream(String companyId) {
    return SupabaseService.client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('company_id', companyId)
        .order('name', ascending: true)
        .map((list) => list.map((json) => LocationModel.fromJson(json)).toList());
  }

  /// Fetch locations (Future-based)
  static Future<List<LocationModel>> getLocations() async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return [];

      final companyId = profile['company_id'];

      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('company_id', companyId)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => LocationModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      return [];
    }
  }

  /// Fetch locations for a specific company
  static Future<List<LocationModel>> getLocationsByCompany(String companyId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('company_id', companyId)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => LocationModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching locations for company $companyId: $e');
      return [];
    }
  }

  /// Create a new location
  static Future<LocationModel?> createLocation(LocationModel location) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .insert(location.toJson())
          .select()
          .single();

      return LocationModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating location: $e');
      return null;
    }
  }

  /// Update a location
  static Future<bool> updateLocation(LocationModel location) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .update(location.toJson())
          .eq('id', location.id);
      return true;
    } catch (e) {
      debugPrint('Error updating location: $e');
      return false;
    }
  }

  /// Delete a location
  static Future<bool> deleteLocation(String id) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting location: $e');
      return false;
    }
  }

  /// Build a hierarchical tree from a flat list of locations
  /// Returns only root nodes (parentId == null), with children nested
  static List<LocationNode> buildTree(List<LocationModel> locations) {
    final Map<String, LocationNode> nodeMap = {};
    final List<LocationNode> roots = [];

    // Create nodes
    for (final loc in locations) {
      nodeMap[loc.id] = LocationNode(location: loc, children: []);
    }

    // Build tree
    for (final loc in locations) {
      final node = nodeMap[loc.id]!;
      if (loc.parentId != null && nodeMap.containsKey(loc.parentId)) {
        nodeMap[loc.parentId]!.children.add(node);
      } else {
        roots.add(node);
      }
    }

    return roots;
  }
}

/// Represents a node in the location hierarchy tree
class LocationNode {
  final LocationModel location;
  final List<LocationNode> children;

  LocationNode({required this.location, required this.children});
}
