import 'base_repository.dart';

/// Abstract repository for translation operations
/// Implementations handle text translation using ML Kit or other services
abstract class ITranslationRepository extends BaseRepository {
  /// Translate text to target language
  Future<String> translateText({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  });

  /// Get available translation languages
  Future<List<String>> getAvailableLanguages();

  /// Get supported language pairs
  Future<List<Map<String, String>>> getSupportedLanguagePairs();

  /// Get translation history
  Future<List<Map<String, dynamic>>> getTranslationHistory({
    int limit = 50,
  });

  /// Clear translation history
  Future<bool> clearTranslationHistory();
}
