import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import 'profile_service.dart';

class EmployeeService {
  static const String _tableName = 'employees';

  // Stream employees (filtered by company if applicable)
  static Stream<List<Map<String, dynamic>>> getEmployeesStream() {
    return Stream.fromFuture(
      ProfileService.getCurrentProfile(),
    ).asyncExpand<List<Map<String, dynamic>>>((profile) {
      if (profile == null) {
        return Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
      }
      
      final companyId = profile['company_id'];

      return SupabaseService.client
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('company_id', companyId)
          .order('name', ascending: true)
          .map((list) => List<Map<String, dynamic>>.from(list));
    }).asBroadcastStream();
  }

  // Stream ALL employees (for Super Admin)
  static Stream<List<Map<String, dynamic>>> getAllEmployeesStream() {
    return SupabaseService.client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false) // Assuming created_at exists, or order by name
        .map((list) => List<Map<String, dynamic>>.from(list));
  }

  // Fetch employees (Future)
  static Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (profile == null) return [];
      
      final companyId = profile['company_id'];

      final response = await SupabaseService.client
          .from(_tableName)
          .select('id, name')
          .eq('company_id', companyId) // Filter by company
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching employees: $e');
      return [];
    }
  }

  // Create a new employee
  // Returns the new employee object or null on failure
  // Create a new employee
  // Returns the new employee object or null on failure
  static Future<Map<String, dynamic>?> createEmployee(String name, {String? companyId}) async {
    try {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) return null;

      String? targetCompanyId = companyId;
      
      if (targetCompanyId == null) {
        final profile = await ProfileService.getCurrentProfile();
        targetCompanyId = profile?['company_id'];
      }

      if (targetCompanyId == null) {
        debugPrint('Error: No company ID provided or found in profile');
        return null; // Cannot create employee without company
      }

      // Check if employee already exists to avoid duplicates (case insensitive)
      final existing = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('company_id', targetCompanyId)
          .ilike('name', trimmedName)
          .maybeSingle();

      if (existing != null) {
        return existing;
      }

      final response = await SupabaseService.client
          .from(_tableName)
          .insert({
            'name': trimmedName,
            'company_id': targetCompanyId,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Error creating employee: $e');
      return null;
    }
  }


  // Update employee details
  static Future<bool> updateEmployee(String id, {String? name, String? companyId}) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (companyId != null) updates['company_id'] = companyId;

      if (updates.isEmpty) return false;

      await SupabaseService.client
          .from(_tableName)
          .update(updates)
          .eq('id', id);
      
      return true;
    } catch (e) {
      debugPrint('Error updating employee: $e');
      return false;
    }
  }

  // Delete an employee
  static Future<bool> deleteEmployee(String id) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting employee: $e');
      return false;
    }
  }
}
