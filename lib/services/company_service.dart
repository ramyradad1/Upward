import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class CompanyService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Cache for the companies list
  static List<Map<String, dynamic>>? _companies;
  
  // Stream controller to broadcast updates
  static final _companiesController = StreamController<List<Map<String, dynamic>>>.broadcast();
  
  // Flag to track if subscription is active
  static bool _isStreamActive = false;

  /// Creates a new company and returns its ID
  static Future<String?> createCompany(String name) async {
    try {
      final response = await _client
          .from('companies')
          .insert({'name': name})
          .select()
          .single();
      
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating company: $e');
      return null;
    }
  }

  /// Fetches all companies (for generic admin view)
  static Future<List<Map<String, dynamic>>> getCompanies() async {
    try {
      final response = await _client
          .from('companies')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching companies: $e');
      return [];
    }
  }

  /// Streams companies for real-time updates (e.g. inside Drawer)
  /// Returns a cached stream so we don't open multiple Realtime connections
  static Stream<List<Map<String, dynamic>>> getCompaniesStream() {
    if (!_isStreamActive) {
      _initStream();
    }
    
    // If we have cached data, emit it immediately to the new listener
    // Note: StreamController.broadcast doesn't replay, so we rely on StreamBuilder's initialData in UI
    // OR we can make a custom stream that emits current value on listen.
    // However, simplest fix without changing UI much is to let the global stream run.
    
    return _companiesController.stream; 
  }

  /// Initializes the single Realtime subscription
  static void _initStream() {
    _isStreamActive = true;
    debugPrint('Initializing CompanyService stream...');
    
    _client
        .from('companies')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
          _companies = data;
          _companiesController.add(data);
        }, onError: (e) {
          debugPrint('Error in company stream: $e');
          _companiesController.addError(e);
        });
  }

  /// Deletes a company by ID
  static Future<bool> deleteCompany(String id) async {
    try {
      await _client.from('companies').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting company: $e');
      return false;
    }
  }

  /// Accessor for current cached value (useful for StreamBuilder initialData)
  static List<Map<String, dynamic>>? get currentCompanies => _companies;
}
