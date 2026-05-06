import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/material.dart';

class ModelDownloadService {
  static final ModelDownloadService _instance =
      ModelDownloadService._internal();

  factory ModelDownloadService() {
    return _instance;
  }

  ModelDownloadService._internal();

  final _modelManager = OnDeviceTranslatorModelManager();
  final _supportedLanguages = [
    TranslateLanguage.english,
    TranslateLanguage.french,
    TranslateLanguage.arabic,
    TranslateLanguage.spanish,
    TranslateLanguage.german,
    TranslateLanguage.italian,
    TranslateLanguage.portuguese,
    TranslateLanguage.japanese,
    TranslateLanguage.chinese,
  ];

  /// Download all translation models at startup
  Future<void> downloadAllModels() async {
    try {
      debugPrint('📥 Starting offline translation models download...');

      for (final language in _supportedLanguages) {
        try {
          final isDownloaded =
              await _modelManager.isModelDownloaded(language.bcpCode);

          if (!isDownloaded) {
            debugPrint('⏳ Downloading model for ${language.bcpCode}...');
            await _modelManager.downloadModel(language.bcpCode);
            debugPrint('✅ Downloaded model for ${language.bcpCode}');
          } else {
            debugPrint('✓ Model ${language.bcpCode} already available');
          }
        } catch (e) {
          debugPrint('⚠️ Error downloading model for ${language.bcpCode}: $e');
        }
      }

      debugPrint('📥 Translation models download complete!');
    } catch (e) {
      debugPrint('❌ Error downloading translation models: $e');
    }
  }

  /// Check if specific language pair is available offline
  Future<bool> isLanguagePairAvailable(String srcCode, String tgtCode) async {
    try {
      final srcReady = await _modelManager.isModelDownloaded(srcCode);
      final tgtReady = await _modelManager.isModelDownloaded(tgtCode);
      return srcReady && tgtReady;
    } catch (_) {
      return false;
    }
  }

  /// Get list of available offline languages
  Future<List<String>> getAvailableOfflineLanguages() async {
    final available = <String>[];
    try {
      for (final language in _supportedLanguages) {
        final isReady = await _modelManager.isModelDownloaded(language.bcpCode);
        if (isReady) {
          available.add(language.bcpCode);
        }
      }
    } catch (_) {
      // Return empty if error
    }
    return available;
  }
}
