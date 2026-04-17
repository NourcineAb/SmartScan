import 'package:shared_preferences/shared_preferences.dart';

/// Stub implementation of NotificationManager for web compatibility
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  late SharedPreferences _prefs;
  bool _notificationsEnabled = true;

  factory NotificationManager() {
    return _instance;
  }

  NotificationManager._internal();

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _notificationsEnabled = _prefs.getBool('enable_notifications') ?? true;
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    _prefs.setBool('enable_notifications', enabled);
  }

  bool get notificationsEnabled => _notificationsEnabled;

  /// Show a simple notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_notificationsEnabled) return;
    // Web stub - notifications not available on web
  }

  /// Schedule a notification at a specific date and time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_notificationsEnabled) return;
    // Web stub - scheduled notifications not available on web
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    // Web stub
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    // Web stub
  }

  /// Show a progress notification (Android only)
  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
    if (!_notificationsEnabled) return;
    // Web stub - progress notifications not available on web
  }
}
