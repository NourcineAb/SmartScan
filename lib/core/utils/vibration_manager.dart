import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// VibrationManager handles haptic feedback on mobile devices
class VibrationManager {
  static final VibrationManager _instance = VibrationManager._internal();
  late SharedPreferences _prefs;
  bool _vibrationEnabled = true;
  bool? _hasVibrator;

  factory VibrationManager() {
    return _instance;
  }

  VibrationManager._internal();

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _vibrationEnabled = _prefs.getBool('enable_vibration') ?? true;

    // Check if device has vibrator (mobile only)
    if (!kIsWeb) {
      _hasVibrator = await Vibration.hasVibrator();
    } else {
      _hasVibrator = false;
    }
  }

  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    _prefs.setBool('enable_vibration', enabled);
  }

  bool get vibrationEnabled => _vibrationEnabled;

  /// Short vibration for tap/button press (30ms)
  Future<void> tapVibration() async {
    if (!_vibrationEnabled || !(_hasVibrator ?? false) || kIsWeb) return;
    try {
      await Vibration.vibrate(duration: 30);
    } catch (_) {}
  }

  /// Success vibration pattern: short-short
  Future<void> successVibration() async {
    if (!_vibrationEnabled || !(_hasVibrator ?? false) || kIsWeb) return;
    try {
      await Vibration.vibrate(pattern: [0, 25, 50, 25]);
    } catch (_) {}
  }

  /// Error vibration pattern
  Future<void> errorVibration() async {
    if (!_vibrationEnabled || !(_hasVibrator ?? false) || kIsWeb) return;
    try {
      await Vibration.vibrate(pattern: [0, 50, 30, 30, 30, 30]);
    } catch (_) {}
  }

  /// Custom vibration with duration in milliseconds
  Future<void> vibrate({required int duration}) async {
    if (!_vibrationEnabled || !(_hasVibrator ?? false) || kIsWeb) return;
    try {
      await Vibration.vibrate(duration: duration);
    } catch (_) {}
  }
}
