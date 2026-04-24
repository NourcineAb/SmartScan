import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  final _connectivity = Connectivity();

  /// Check if device has internet connectivity
  /// Returns true if WiFi, mobile, or other network is available
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
      debugPrint(
          '📡 Internet check: ${hasConnection ? '✅ Connected' : '❌ No connection'}');
      return hasConnection;
    } catch (e) {
      debugPrint('⚠️ Error checking connectivity: $e');
      // If we can't determine, assume we have internet to allow API attempts
      return true;
    }
  }

  /// Get the type of connection (WiFi, Mobile, or None)
  Future<ConnectivityResult> getConnectionType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      // Return first non-none result, or none if all are none
      for (final result in results) {
        if (result != ConnectivityResult.none) {
          return result;
        }
      }
      return ConnectivityResult.none;
    } catch (e) {
      debugPrint('⚠️ Error getting connection type: $e');
      return ConnectivityResult.none;
    }
  }

  /// Watch connectivity changes in real time
  /// Useful for showing connection status indicators
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged
        .map((result) => result != ConnectivityResult.none);
  }
}
