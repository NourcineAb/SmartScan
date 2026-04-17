import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

/// SoundManager handles sound effects and audio playback
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  late SharedPreferences _prefs;
  late AudioPlayer _audioPlayer;
  bool _soundsEnabled = true;

  factory SoundManager() {
    return _instance;
  }

  SoundManager._internal() {
    _audioPlayer = AudioPlayer();
  }

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _soundsEnabled = _prefs.getBool('enable_sounds') ?? true;

    // Set audio context for background audio (mobile only)
    if (!kIsWeb) {
      try {
        await _audioPlayer.setAudioContext(
          AudioContext(
            android: AudioContextAndroid(
              audioFocus: AndroidAudioFocus.gain,
              isSpeakerphoneOn: false,
              stayAwake: false,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
            ),
          ),
        );
      } catch (_) {
        // Silently ignore audio context errors
      }
    }
  }

  void setSoundsEnabled(bool enabled) {
    _soundsEnabled = enabled;
    _prefs.setBool('enable_sounds', enabled);
  }

  bool get soundsEnabled => _soundsEnabled;

  /// Play shutter/camera capture sound
  Future<void> playShutterSound() async {
    if (!_soundsEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('sounds/shutter.mp3'),
        volume: 1.0,
      );
    } catch (_) {
      // Silently fail if sound is not available
    }
  }

  /// Play success confirmation sound
  Future<void> playSuccessSound() async {
    if (!_soundsEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('sounds/success.mp3'),
        volume: 0.8,
      );
    } catch (_) {
      // Silently fail if sound is not available
    }
  }

  /// Play save confirmation sound
  Future<void> playSaveSound() async {
    if (!_soundsEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('sounds/save.mp3'),
        volume: 0.8,
      );
    } catch (_) {
      // Silently fail if sound is not available
    }
  }

  /// Play error sound
  Future<void> playErrorSound() async {
    if (!_soundsEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('sounds/error.mp3'),
        volume: 0.8,
      );
    } catch (_) {
      // Silently fail if sound is not available
    }
  }

  /// Play tap/button press sound
  Future<void> playTapSound() async {
    if (!_soundsEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('sounds/tap.mp3'),
        volume: 0.6,
      );
    } catch (_) {
      // Silently fail if sound is not available
    }
  }

  /// Dispose audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}
