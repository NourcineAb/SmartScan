import 'package:google_mlkit_language_id/google_mlkit_language_id.dart' as ml_kit_lang;
import 'package:google_mlkit_translation/google_mlkit_translation.dart' as ml_kit_trans;
import 'package:flutter/foundation.dart';

/// Language detection and translation result
class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final double confidence;
  final bool isTranslated;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.confidence = 1.0,
    this.isTranslated = true,
  });
}

/// Language detection and translation service
class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  ml_kit_lang.LanguageIdentifier? _languageIdentifier;
  final Map<String, ml_kit_trans.OnDeviceTranslator> _translators = {};

  /// Supported language codes
  static const supportedLanguages = {
    'en': 'English',
    'fr': 'French',
    'es': 'Spanish',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'nl': 'Dutch',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'ru': 'Russian',
    'tr': 'Turkish',
    'pl': 'Polish',
  };

  ml_kit_lang.LanguageIdentifier _getLanguageIdentifier() {
    _languageIdentifier ??= ml_kit_lang.LanguageIdentifier(confidenceThreshold: 0.5);
    return _languageIdentifier!;
  }

  /// Detect the language of text
  Future<String> detectLanguage(String text) async {
    if (text.trim().isEmpty) return 'en';

    // On web, use simple heuristic
    if (kIsWeb) {
      return _detectLanguageHeuristic(text);
    }

    try {
      final identifier = _getLanguageIdentifier();
      final languages = await identifier.identifyPossibleLanguages(text);
      
      if (languages.isNotEmpty) {
        return languages.first.languageTag;
      }
    } catch (e) {
      debugPrint('Language detection error: $e');
    }

    return 'en'; // Default to English
  }

  /// Simple heuristic language detection for web/fallback
  String _detectLanguageHeuristic(String text) {
    final sample = text.toLowerCase().substring(0, text.length > 100 ? 100 : text.length);

    // French patterns
    if (sample.contains(' le ') || sample.contains(' la ') || sample.contains(' les ') ||
        sample.contains(' un ') || sample.contains(' une ') || sample.contains(' et ') ||
        sample.contains(' à ') || sample.contains(' é')) {
      return 'fr';
    }

    // Spanish patterns
    if (sample.contains(' el ') || sample.contains(' la ') || sample.contains(' los ') ||
        sample.contains(' un ') || sample.contains(' una ') || sample.contains(' y ') ||
        sample.contains(' ñ')) {
      return 'es';
    }

    // German patterns
    if (sample.contains(' der ') || sample.contains(' die ') || sample.contains(' das ') ||
        sample.contains(' und ') || sample.contains(' für ') || sample.contains(' ß')) {
      return 'de';
    }

    // Arabic patterns
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(sample)) {
      return 'ar';
    }

    // Chinese patterns
    if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(sample)) {
      return 'zh';
    }

    // Japanese patterns
    if (RegExp(r'[\u3040-\u309F\u30A0-\u30FF]').hasMatch(sample)) {
      return 'ja';
    }

    // Russian patterns
    if (RegExp(r'[\u0400-\u04FF]').hasMatch(sample)) {
      return 'ru';
    }

    return 'en';
  }

  /// Translate text from source to target language
  Future<TranslationResult> translate({
    required String text,
    String? sourceLanguage,
    required String targetLanguage,
  }) async {
    if (text.trim().isEmpty) {
      return TranslationResult(
        originalText: text,
        translatedText: text,
        sourceLanguage: sourceLanguage ?? 'en',
        targetLanguage: targetLanguage,
        isTranslated: false,
      );
    }

    // If source language not specified, detect it
    final source = sourceLanguage ?? await detectLanguage(text);

    // If source equals target, no translation needed
    if (source == targetLanguage) {
      return TranslationResult(
        originalText: text,
        translatedText: text,
        sourceLanguage: source,
        targetLanguage: targetLanguage,
        isTranslated: false,
      );
    }

    // On web, use mock translation
    if (kIsWeb) {
      return _mockTranslate(
        text: text,
        sourceLanguage: source,
        targetLanguage: targetLanguage,
      );
    }

    try {
      final translator = _getTranslator(source, targetLanguage);
      final translated = await translator.translateText(text);

      return TranslationResult(
        originalText: text,
        translatedText: translated,
        sourceLanguage: source,
        targetLanguage: targetLanguage,
        isTranslated: true,
      );
    } catch (e) {
      debugPrint('Translation error: $e');
      // Fallback to mock translation
      return _mockTranslate(
        text: text,
        sourceLanguage: source,
        targetLanguage: targetLanguage,
      );
    }
  }

  /// Get or create translator for language pair
  ml_kit_trans.OnDeviceTranslator _getTranslator(
    String source,
    String target,
  ) {
    final key = '${source}_$target';
    
    if (!_translators.containsKey(key)) {
      _translators[key] = ml_kit_trans.OnDeviceTranslator(
        sourceLanguage: ml_kit_trans.TranslateLanguage.values.firstWhere(
          (l) => l.bcpCode == source,
          orElse: () => ml_kit_trans.TranslateLanguage.english,
        ),
        targetLanguage: ml_kit_trans.TranslateLanguage.values.firstWhere(
          (l) => l.bcpCode == target,
          orElse: () => ml_kit_trans.TranslateLanguage.english,
        ),
      );
    }
    
    return _translators[key]!;
  }

  /// Mock translation for web/fallback
  TranslationResult _mockTranslate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    // Simple mock: add a prefix to indicate translation
    final sourceName = supportedLanguages[sourceLanguage] ?? sourceLanguage;
    final targetName = supportedLanguages[targetLanguage] ?? targetLanguage;
    
    final mockTranslation = '[$targetName translation]\n\n$text';

    return TranslationResult(
      originalText: text,
      translatedText: mockTranslation,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      isTranslated: sourceLanguage != targetLanguage,
    );
  }

  /// Get display name for language code
  String getLanguageName(String code) {
    return supportedLanguages[code] ?? code.toUpperCase();
  }

  /// Check if translation is supported between two languages
  bool isTranslationSupported(String source, String target) {
    return supportedLanguages.containsKey(source) && 
           supportedLanguages.containsKey(target);
  }

  /// Get list of supported language codes
  List<String> getSupportedLanguages() {
    return supportedLanguages.keys.toList();
  }

  /// Reset translators to free resources
  void reset() {
    debugPrint('♻️ Resetting LanguageService...');
    _languageIdentifier?.close();
    _languageIdentifier = null;
    
    for (final translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
  }
}
