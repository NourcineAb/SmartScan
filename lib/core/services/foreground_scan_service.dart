import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ForegroundScanService {
  ForegroundScanService._();

  static const _channel = MethodChannel('smart.scan/foreground_service');

  static Future<void> start() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('start');
      debugPrint('🛡️ ForegroundScanService: started');
    } catch (e) {
      debugPrint('ForegroundScanService.start failed: $e');
    }
  }

  static Future<void> stop() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stop');
      debugPrint('🛡️ ForegroundScanService: stopped');
    } catch (e) {
      debugPrint('ForegroundScanService.stop failed: $e');
    }
  }
}
