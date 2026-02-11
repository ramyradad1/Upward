import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/license_model.dart';

class LicenseService {
  static final _supabase = Supabase.instance.client;
  static final _streamController = StreamController<List<LicenseModel>>.broadcast();
  static List<LicenseModel> _cachedLicenses = [];

  // Stream of licenses
  static Stream<List<LicenseModel>> getLicensesStream() {
    _initializeStream();
    return _streamController.stream;
  }

  static void _initializeStream() {
    if (_cachedLicenses.isEmpty) {
      _fetchLicenses();
    }

    _supabase
        .from('licenses')
        .stream(primaryKey: ['id'])
        .listen((data) {
          _cachedLicenses = data.map((json) => LicenseModel.fromJson(json)).toList();
          _streamController.add(_cachedLicenses);
        });
  }

  static Future<void> _fetchLicenses() async {
    try {
      final response = await _supabase
          .from('licenses')
          .select()
          .order('created_at', ascending: false);
      
      _cachedLicenses = (response as List)
          .map((json) => LicenseModel.fromJson(json))
          .toList();
      _streamController.add(_cachedLicenses);
    } catch (e) {
      debugPrint('Error fetching licenses: $e');
    }
  }

  // Get all licenses
  static Future<List<LicenseModel>> getLicenses() async {
    try {
      final response = await _supabase
          .from('licenses')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => LicenseModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting licenses: $e');
      return [];
    }
  }

  // Get license by ID
  static Future<LicenseModel?> getLicenseById(String id) async {
    try {
      final response = await _supabase
          .from('licenses')
          .select()
          .eq('id', id)
          .single();
      
      return LicenseModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting license: $e');
      return null;
    }
  }

  // Create license
  static Future<LicenseModel?> createLicense(LicenseModel license) async {
    try {
      final response = await _supabase
          .from('licenses')
          .insert(license.toJson())
          .select()
          .single();
      
      return LicenseModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating license: $e');
      return null;
    }
  }

  // Update license
  static Future<bool> updateLicense(LicenseModel license) async {
    try {
      await _supabase
          .from('licenses')
          .update(license.toJson())
          .eq('id', license.id);
      
      return true;
    } catch (e) {
      debugPrint('Error updating license: $e');
      return false;
    }
  }

  // Delete license
  static Future<bool> deleteLicense(String id) async {
    try {
      await _supabase
          .from('licenses')
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting license: $e');
      return false;
    }
  }

  // Get expiring licenses (within days)
  static Future<List<LicenseModel>> getExpiringLicenses({int days = 30}) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: days));
      
      final response = await _supabase
          .from('licenses')
          .select()
          .gte('expiry_date', now.toIso8601String())
          .lte('expiry_date', futureDate.toIso8601String())
          .order('expiry_date', ascending: true);
      
      return (response as List)
          .map((json) => LicenseModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting expiring licenses: $e');
      return [];
    }
  }

  // Get licenses by company
  static Future<List<LicenseModel>> getLicensesByCompany(String companyId) async {
    try {
      final response = await _supabase
          .from('licenses')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => LicenseModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting licenses by company: $e');
      return [];
    }
  }

  // Get total cost for all licenses
  static Future<double> getTotalLicenseCost() async {
    try {
      final licenses = await getLicenses();
      return licenses.fold<double>(0.0, (double sum, license) => sum + (license.totalCost ?? 0));
    } catch (e) {
      debugPrint('Error calculating total cost: $e');
      return 0.0;
    }
  }

  // Get seat utilization stats
  static Future<Map<String, int>> getSeatStats() async {
    try {
      final licenses = await getLicenses();
      final totalSeats = licenses.fold(0, (sum, license) => sum + license.totalSeats);
      final usedSeats = licenses.fold(0, (sum, license) => sum + license.usedSeats);
      
      return {
        'total': totalSeats,
        'used': usedSeats,
        'available': totalSeats - usedSeats,
      };
    } catch (e) {
      debugPrint('Error calculating seat stats: $e');
      return {'total': 0, 'used': 0, 'available': 0};
    }
  }

  static void dispose() {
    _streamController.close();
  }
}
