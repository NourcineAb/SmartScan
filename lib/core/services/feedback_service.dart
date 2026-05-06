import 'package:audioplayers/audioplayers.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Singleton service for sound and haptic feedback.
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  AudioPlayer? _tapPlayer;
  AudioPlayer? _shutterPlayer;
  AudioPlayer? _successPlayer;
  AudioPlayer? _errorPlayer;
  AudioPlayer? _savePlayer;
  AudioPlayer? _deletePlayer;
  AudioPlayer? _vibrationPlayer;

  AudioPlayer _getTapPlayer() => _tapPlayer ??= AudioPlayer();
  AudioPlayer _getShutterPlayer() => _shutterPlayer ??= AudioPlayer();
  AudioPlayer _getSuccessPlayer() => _successPlayer ??= AudioPlayer();
  AudioPlayer _getErrorPlayer() => _errorPlayer ??= AudioPlayer();
  AudioPlayer _getSavePlayer() => _savePlayer ??= AudioPlayer();
  AudioPlayer _getDeletePlayer() => _deletePlayer ??= AudioPlayer();
  AudioPlayer _getVibrationPlayer() => _vibrationPlayer ??= AudioPlayer();

  // ─── Settings helpers ──────────────────────────────────────────────────────

  Future<bool> get _soundEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enable_sounds') ?? true;
  }

  Future<bool> get _vibrationEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enable_vibration') ?? true;
  }

  // ─── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _play(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset), volume: 1.0);
    } catch (_) {}
  }

  Future<void> _haptic(HapticsType type) async {
    try {
      if (await Haptics.canVibrate()) {
        await Haptics.vibrate(type);
      }
    } on PlatformException catch (_) {
      // Ignore haptic errors
    } catch (_) {}
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Light tap — for general button presses.
  Future<void> onTap() async {
    if (await _vibrationEnabled) {
      await _haptic(HapticsType.selection);
    }
  }

  /// Camera shutter — when a photo is taken.
  Future<void> onShutter() async {
    if (await _soundEnabled) _play(_getShutterPlayer(), 'sounds/shutter.mp3');
    if (await _vibrationEnabled) await _haptic(HapticsType.medium);
  }

  /// Success — scan saved, translation done, etc.
  Future<void> onSuccess() async {
    if (await _soundEnabled) _play(_getSuccessPlayer(), 'sounds/success.mp3');
    if (await _vibrationEnabled) await _haptic(HapticsType.success);
  }

  /// Save — file saved or exported.
  Future<void> onSave() async {
    if (await _soundEnabled) _play(_getSavePlayer(), 'sounds/save.mp3');
    if (await _vibrationEnabled) await _haptic(HapticsType.heavy);
  }

  /// Error — something went wrong.
  Future<void> onError() async {
    if (await _soundEnabled) _play(_getErrorPlayer(), 'sounds/error.mp3');
    if (await _vibrationEnabled) await _haptic(HapticsType.error);
  }

  /// Delete — category or item deleted.
  Future<void> onDelete() async {
    if (await _soundEnabled) _play(_getDeletePlayer(), 'sounds/delete.mp3');
    if (await _vibrationEnabled) await _haptic(HapticsType.warning);
  }

  /// Vibration toggle — when vibration setting is changed.
  Future<void> onVibration() async {
    if (await _soundEnabled) _play(_getVibrationPlayer(), 'sounds/vibration.mp3');
    if (await _vibrationEnabled) await _haptic(HapticsType.selection);
  }

  /// Vibration toggle — plays sound when disabling, haptic when enabling.
  Future<void> onVibrationToggled(bool isEnabled) async {
    if (!isEnabled) {
      if (await _soundEnabled) _play(_getVibrationPlayer(), 'sounds/vibration.mp3');
    } else {
      if (await _vibrationEnabled) await _haptic(HapticsType.selection);
    }
  }

  void reset() {
    debugPrint('♻️ Resetting FeedbackService...');
    _tapPlayer?.dispose();
    _shutterPlayer?.dispose();
    _successPlayer?.dispose();
    _errorPlayer?.dispose();
    _savePlayer?.dispose();
    _deletePlayer?.dispose();
    _vibrationPlayer?.dispose();

    _tapPlayer = null;
    _shutterPlayer = null;
    _successPlayer = null;
    _errorPlayer = null;
    _savePlayer = null;
    _deletePlayer = null;
    _vibrationPlayer = null;
  }

  void dispose() {
    reset();
  }
}
