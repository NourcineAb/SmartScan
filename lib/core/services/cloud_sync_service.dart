import 'package:shared_preferences/shared_preferences.dart';

/// Stub implementation of CloudSyncService for web compatibility
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  late SharedPreferences _prefs;
  bool _syncEnabled = false;

  factory CloudSyncService() {
    return _instance;
  }

  CloudSyncService._internal();

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _syncEnabled = _prefs.getBool('enable_cloud_sync') ?? false;
  }

  void setCloudSyncEnabled(bool enabled) {
    _syncEnabled = enabled;
    _prefs.setBool('enable_cloud_sync', enabled);
  }

  bool get cloudSyncEnabled => _syncEnabled;

  /// Upload a scan to cloud storage
  Future<void> uploadScan({
    required String scanId,
    required String title,
    required String rawText,
    required String? imagePath,
  }) async {
    if (!_syncEnabled) return;
    // Web stub - cloud sync not available in this demo
  }

  /// Upload an image to Firebase Storage
  Future<void> uploadImage({
    required String imagePath,
    required String fileName,
  }) async {
    if (!_syncEnabled) return;
    // Web stub - image upload not available in this demo
  }

  /// Download a scan from Firestore
  Future<Map<String, dynamic>?> downloadScan(String scanId) async {
    if (!_syncEnabled) return null;
    // Web stub - download not available in this demo
    return null;
  }

  /// Sync all scans with cloud
  Future<void> syncAllScans(List<Map<String, dynamic>> scans) async {
    if (!_syncEnabled) return;
    // Web stub - sync not available in this demo
  }

  /// Delete a scan from cloud
  Future<void> deleteScan(String scanId) async {
    if (!_syncEnabled) return;
    // Web stub - delete not available in this demo
  }
}
