import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics service for tracking app events
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  bool _enabled = true;
  bool _isWeb = false;

  /// Initialize the analytics service
  Future<void> initialize() async {
    try {
      // Check if running on web
      _isWeb = kIsWeb;
      
      if (!_isWeb) {
        _analytics = FirebaseAnalytics.instance;
        await _analytics!.setAnalyticsCollectionEnabled(true);
      }
    } catch (e) {
      debugPrint('Analytics initialization error: $e');
      _enabled = false;
    }
  }

  /// Enable or disable analytics collection
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!_isWeb && _analytics != null) {
      await _analytics!.setAnalyticsCollectionEnabled(enabled);
    }
  }

  /// Track scan completion
  Future<void> logScanCompleted({
    required String scanId,
    String? detectedLanguage,
    int? textLength,
    bool isMock = false,
  }) async {
    await _logEvent(
      name: 'scan_completed',
      parameters: {
        'scan_id': scanId,
        if (detectedLanguage != null) 'detected_language': detectedLanguage,
        if (textLength != null) 'text_length': textLength,
        'is_mock': isMock,
      },
    );
  }

  /// Track entity detection
  Future<void> logEntityDetected({
    required String scanId,
    required String entityType,
    int entityCount = 1,
  }) async {
    await _logEvent(
      name: 'entity_detected',
      parameters: {
        'scan_id': scanId,
        'entity_type': entityType,
        'entity_count': entityCount,
      },
    );
  }

  /// Track reminder suggestion
  Future<void> logReminderSuggested({
    required String scanId,
    required String suggestionId,
    required String sourceType,
    double? confidence,
  }) async {
    await _logEvent(
      name: 'reminder_suggested',
      parameters: {
        'scan_id': scanId,
        'suggestion_id': suggestionId,
        'source_type': sourceType,
        if (confidence != null) 'confidence': confidence,
      },
    );
  }

  /// Track reminder creation
  Future<void> logReminderCreated({
    required String scanId,
    required String reminderId,
    String? triggerSource,
  }) async {
    await _logEvent(
      name: 'reminder_created',
      parameters: {
        'scan_id': scanId,
        'reminder_id': reminderId,
        if (triggerSource != null) 'trigger_source': triggerSource,
      },
    );
  }

  /// Track reminder dismissal
  Future<void> logReminderDismissed({
    required String scanId,
    required String suggestionId,
  }) async {
    await _logEvent(
      name: 'reminder_dismissed',
      parameters: {
        'scan_id': scanId,
        'suggestion_id': suggestionId,
      },
    );
  }

  /// Track document type detection
  Future<void> logDocumentTypeDetected({
    required String scanId,
    required String documentType,
    double? confidence,
  }) async {
    await _logEvent(
      name: 'document_type_detected',
      parameters: {
        'scan_id': scanId,
        'document_type': documentType,
        if (confidence != null) 'confidence': confidence,
      },
    );
  }

  /// Track translation usage
  Future<void> logTranslationUsed({
    required String scanId,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    await _logEvent(
      name: 'translation_used',
      parameters: {
        'scan_id': scanId,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
      },
    );
  }

  /// Track export action
  Future<void> logExport({
    required String scanId,
    required String format,
  }) async {
    await _logEvent(
      name: 'export',
      parameters: {
        'scan_id': scanId,
        'format': format,
      },
    );
  }

  /// Track search usage
  Future<void> logSearch({
    required String query,
    int resultCount = 0,
  }) async {
    await _logEvent(
      name: 'search',
      parameters: {
        'query_length': query.length,
        'result_count': resultCount,
      },
    );
  }

  /// Track category selection
  Future<void> logCategorySelected({
    required String scanId,
    required String categoryId,
  }) async {
    await _logEvent(
      name: 'category_selected',
      parameters: {
        'scan_id': scanId,
        'category_id': categoryId,
      },
    );
  }

  /// Track smart crop usage
  Future<void> logSmartCropUsed({
    required String scanId,
    bool accepted = true,
  }) async {
    await _logEvent(
      name: 'smart_crop_used',
      parameters: {
        'scan_id': scanId,
        'accepted': accepted,
      },
    );
  }

  /// Track highlight interaction
  Future<void> logHighlightTapped({
    required String scanId,
    required String entityType,
  }) async {
    await _logEvent(
      name: 'highlight_tapped',
      parameters: {
        'scan_id': scanId,
        'entity_type': entityType,
      },
    );
  }

  /// Track fullscreen viewer usage
  Future<void> logFullscreenViewed({
    required String scanId,
    int durationSeconds = 0,
  }) async {
    await _logEvent(
      name: 'fullscreen_viewed',
      parameters: {
        'scan_id': scanId,
        'duration_seconds': durationSeconds,
      },
    );
  }

  /// Track error events
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? scanId,
  }) async {
    await _logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage.substring(0, errorMessage.length > 100 ? 100 : errorMessage.length),
        if (scanId != null) 'scan_id': scanId,
      },
    );
  }

  /// Track app open
  Future<void> logAppOpen() async {
    await _logEvent(name: 'app_open');
  }

  /// Track screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_enabled) return;

    try {
      if (!_isWeb && _analytics != null) {
        await _analytics!.logScreenView(
          screenName: screenName,
          screenClass: screenClass ?? screenName,
        );
      } else {
        _logToConsole('screen_view', {
          'screen_name': screenName,
          'screen_class': screenClass ?? screenName,
        });
      }
    } catch (e) {
      debugPrint('Analytics screen view error: $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperties({
    String? userId,
    String? language,
    String? theme,
  }) async {
    if (!_enabled) return;

    try {
      if (!_isWeb && _analytics != null) {
        if (userId != null) {
          await _analytics!.setUserId(id: userId);
        }
        if (language != null) {
          await _analytics!.setUserProperty(name: 'app_language', value: language);
        }
        if (theme != null) {
          await _analytics!.setUserProperty(name: 'app_theme', value: theme);
        }
      }
    } catch (e) {
      debugPrint('Analytics set user properties error: $e');
    }
  }

  /// Internal method to log events
  Future<void> _logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_enabled) return;

    try {
      if (!_isWeb && _analytics != null) {
        // Convert parameters to required format
        final params = parameters?.map(
          (key, value) => MapEntry(key, _convertParameter(value)),
        );
        await _analytics!.logEvent(
          name: name,
          parameters: params,
        );
      } else {
        _logToConsole(name, parameters);
      }
    } catch (e) {
      debugPrint('Analytics log event error: $e');
    }
  }

  /// Convert parameter value to supported type
  Object _convertParameter(dynamic value) {
    if (value is String) return value;
    if (value is int) return value;
    if (value is double) return value;
    if (value is bool) return value ? 1 : 0;
    return value.toString();
  }

  /// Log to console for web/debug mode
  void _logToConsole(String name, Map<String, dynamic>? parameters) {
    if (kDebugMode) {
      debugPrint('📊 Analytics: $name ${parameters ?? ''}');
    }
  }
}
