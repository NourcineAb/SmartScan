import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service for sound and haptic feedback.
/// Reads enable/disable flags from SharedPreferences on every call so it always
/// reflects the latest user setting without requiring a restart.
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  // One AudioPlayer per sound so overlapping sounds don't cut each other off
  final AudioPlayer _tapPlayer = AudioPlayer();
  final AudioPlayer _shutterPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();
  final AudioPlayer _errorPlayer = AudioPlayer();
  final AudioPlayer _savePlayer = AudioPlayer();
  final AudioPlayer _deletePlayer = AudioPlayer();
  final AudioPlayer _vibrationPlayer = AudioPlayer();

  // ─── Settings helpers ──────────────────────────────────────────────────────

  Future<bool> get _soundEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enable_sounds') ?? true;
  }

  Future<bool> get _vibrationEnabled async {
    // Vibration has been disabled
    return false;
  }

  // ─── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _play(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset), volume: 0.8);
    } catch (_) {
      // Never crash the UI due to audio failure
    }
  }

  Future<void> _buzz(int ms) async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: ms);
      }
    } catch (_) {}
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Light tap — for general button presses.
  Future<void> onTap() async {
    if (await _soundEnabled) _play(_tapPlayer, 'sounds/tap.mp3');
    if (await _vibrationEnabled) _buzz(18);
  }

  /// Camera shutter — when a photo is taken.
  Future<void> onShutter() async {
    if (await _soundEnabled) _play(_shutterPlayer, 'sounds/shutter.mp3');
    if (await _vibrationEnabled) _buzz(35);
  }

  /// Success — scan saved, translation done, etc.
  Future<void> onSuccess() async {
    if (await _soundEnabled) _play(_successPlayer, 'sounds/success.mp3');
    if (await _vibrationEnabled) _buzz(60);
  }

  /// Save — file saved or exported.
  Future<void> onSave() async {
    if (await _soundEnabled) _play(_savePlayer, 'sounds/save.mp3');
    if (await _vibrationEnabled) _buzz(80);
  }

  /// Error — something went wrong.
  Future<void> onError() async {
    if (await _soundEnabled) _play(_errorPlayer, 'sounds/error.mp3');
    if (await _vibrationEnabled) _buzz(120);
  }

  /// Delete — category or item deleted.
  Future<void> onDelete() async {
    if (await _soundEnabled) _play(_deletePlayer, 'sounds/delete.mp3');
    if (await _vibrationEnabled) _buzz(50);
  }

  /// Vibration toggle — when vibration setting is changed.
  Future<void> onVibration() async {
    if (await _soundEnabled) _play(_vibrationPlayer, 'sounds/vibration.mp3');
    if (await _vibrationEnabled) _buzz(40);
  }

  /// Vibration toggle with conditional logic
  /// Only plays sound when DISABLING vibration, not when enabling
  Future<void> onVibrationToggled(bool isEnabled) async {
    if (!isEnabled) {
      // Disabling vibration - play sound only
      if (await _soundEnabled) _play(_vibrationPlayer, 'sounds/vibration.mp3');
    } else {
      // Activating vibration - just vibrate, no sound
      if (await _vibrationEnabled) _buzz(40);
    }
  }

  void dispose() {
    _tapPlayer.dispose();
    _shutterPlayer.dispose();
    _successPlayer.dispose();
    _errorPlayer.dispose();
    _savePlayer.dispose();
    _deletePlayer.dispose();
    _vibrationPlayer.dispose();
  }
}
