class AppConstants {
  // Ignored patterns for sensitive data
  static const String appName = 'SmartScan';
  static const String appVersion = '1.0.0';

  // Database constants
  static const String databaseName = 'smartscan.db';
  static const int databaseVersion = 3;

  // Table names
  static const String tableScans = 'scans';
  static const String tableCategories = 'categories';
  static const String tableSavedTranslations = 'saved_translations';

  // Shared preferences keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefEnableSounds = 'enable_sounds';
  static const String prefEnableButtonSounds = 'enable_button_sounds';
  static const String prefEnableVibration = 'enable_vibration';
  static const String prefEnableNotifications = 'enable_notifications';
  static const String prefReminderFrequency = 'reminder_frequency';
  static const String prefOnboardingCompleted = 'onboarding_completed';

  // Default values
  static const String defaultLanguage = 'en';
  static const bool defaultSoundEnabled = true;
  static const bool defaultVibrationEnabled = true;
  static const bool defaultNotificationsEnabled = true;

  // Firebase collections
  static const String firestoreScans = 'scans';
  static const String firestoreUsers = 'users';

  // Timeouts
  static const Duration cameraInitTimeout = Duration(seconds: 5);
  static const Duration ocrProcessTimeout = Duration(seconds: 30);
  static const Duration translationTimeout = Duration(seconds: 15);

  // Image size constraints
  static const int maxImageWidth = 1280;
  static const int maxImageHeight = 1280;
  static const int jpegQuality = 90;

  // Pagination
  static const int pageSize = 20;

  // Reminder frequencies
  static const Map<String, int> reminderFrequencies = {
    'daily': 1,
    'weekly': 7,
    'never': 0,
  };
}
