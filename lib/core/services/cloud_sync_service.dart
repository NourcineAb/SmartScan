import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  late SharedPreferences _prefs;
  bool _syncEnabled = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  final ValueNotifier<double?> syncProgress = ValueNotifier(null);

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
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_syncEnabled || _auth.currentUser == null) return;
    try {
      // image upload removed; text-only sync

      final scanData = {
        'id': scanId,
        'title': title,
        'raw_text': rawText,
        'updated_at': DateTime.now().toIso8601String(),
        ...?additionalData,
      };

      // strip local path before sync
      scanData.remove('image_path');

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('scans')
          .doc(scanId)
          .set(scanData, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print("Upload scan error: \$e");
      }
    }
  }

  /// Download a scan from Firestore
  Future<Map<String, dynamic>?> downloadScan(String scanId) async {
    if (!_syncEnabled || _auth.currentUser == null) return null;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('scans')
          .doc(scanId)
          .get();

      return doc.data();
    } catch (e) {
      print("Download scan error: \$e");
      return null;
    }
  }

  /// Sync all scans with cloud
  Future<void> syncAllScans(List<Map<String, dynamic>> scans) async {
    if (!_syncEnabled || _auth.currentUser == null || scans.isEmpty) return;

    syncProgress.value = 0.0;
    for (int i = 0; i < scans.length; i++) {
      var scan = scans[i];
      await uploadScan(
        scanId: scan['id'],
        title: scan['title'] ?? 'Untitled',
        rawText: scan['raw_text'] ?? '',
        imagePath: scan['image_path'],
        additionalData: scan,
      );
      syncProgress.value = (i + 1) / scans.length;
    }

    // Hold 100% for a brief moment before hiding
    await Future.delayed(const Duration(milliseconds: 500));
    syncProgress.value = null;
  }

  /// Delete a scan from cloud
  Future<void> deleteScan(String scanId) async {
    if (!_syncEnabled || _auth.currentUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('scans')
          .doc(scanId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        print("Delete scan error: \$e");
      }
    }
  }
}
