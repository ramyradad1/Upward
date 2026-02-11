import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class ProfileService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Creates a profile linked to an Auth User ID
  static Future<void> createProfile({
    required String userId,
    required String email,
    required String companyId,
    required String role, // 'admin', 'user'
    String? name,
    bool appAccess = false,
    bool adminPanelAccess = false,
  }) async {
    await _client.from('profiles').insert({
      'id': userId,
      'email': email,
      'company_id': companyId,
      'role': role,
      'name': name,
      'app_access': appAccess,
      'admin_panel_access': adminPanelAccess,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetches the current user's profile including company_id and role
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }
}
