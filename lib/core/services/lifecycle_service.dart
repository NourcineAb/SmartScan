import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'language_service.dart';
import 'entity_extraction_service.dart';
import 'feedback_service.dart';
import '../../features/scan/data/services/ocr_service.dart';

/// Service to handle global application lifecycle events

class AppLifecycleService extends WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  bool _isInitialized = false;
  DateTime? _lastCleanup;
  static const _cleanupThrottle = Duration(seconds: 2);
  bool _isScannerActive = false;

  /// Call this to disable automatic cleanup during heavy native activities
  set isScannerActive(bool value) {
    _isScannerActive = value;
    if (value) debugPrint('🛡️ AppLifecycleService: Auto-cleanup DISABLED (Scanner Active)');
    else debugPrint('🛡️ AppLifecycleService: Auto-cleanup ENABLED');
  }

  void initialize() {
    if (_isInitialized) return;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    debugPrint('🔄 AppLifecycleService initialized');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 App Lifecycle State: ${state.name}');

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_isScannerActive) {
        debugPrint('⏭️ Skipping background cleanup (Scanner Active)');
        return;
      }

      final now = DateTime.now();
      if (_lastCleanup == null ||
          now.difference(_lastCleanup!) > _cleanupThrottle) {
        _performCleanup();
        _lastCleanup = now;
      }
    }
  }

  /// Manually trigger memory cleanup after heavy operations.
  /// Schedules for next frame so it doesn't dirty widgets mid-build.
  void manualCleanup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performCleanup();
    });
  }

  void heavyCleanup() {
    debugPrint(
        '🚀 [CRITICAL] Performing heavy cleanup before native activity...');
    _performCleanup();

    try {
      // ignore: unused_local_variable
      final _ = List.filled(1024 * 1024, 0); // 1 MB allocation triggers GC
    } catch (_) {}
  }

  void _performCleanup() {
    debugPrint('🧹 Performing memory cleanup...');

    try {
      PaintingBinding.instance.imageCache.maximumSize = 0;
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes =
          512 * 1024 * 1024; // 512 MB
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }

    // Reset services to free up native resources
    try {
      OCRService().reset();
      LanguageService().reset();
      EntityExtractionService().reset();
      FeedbackService().reset();
    } catch (e) {
      debugPrint('Error resetting services: $e');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }
}
