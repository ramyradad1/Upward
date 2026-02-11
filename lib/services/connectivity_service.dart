import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionChangeController = StreamController<bool>.broadcast();
  bool _isOnline = true;

  bool get isOnline => _isOnline;
  Stream<bool> get connectionStream => _connectionChangeController.stream;

  static Future<void> init() async {
    await _instance._initialCheck();
    _instance._connectivity.onConnectivityChanged.listen(_instance._connectionChange);
  }

  Future<void> _initialCheck() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = _hasConnection(result);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      _isOnline = true; // Assume online on error to avoid blocking
    }
  }

  void _connectionChange(List<ConnectivityResult> results) {
    bool hasConnection = _hasConnection(results);
    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      _connectionChangeController.add(_isOnline);
      debugPrint('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
    }
  }
  
  // Helper to check if any result in the list indicates a connection
  bool _hasConnection(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.any((r) => r != ConnectivityResult.none);
    }
    return result != ConnectivityResult.none;
  }

  void dispose() {
    _connectionChangeController.close();
  }
}
