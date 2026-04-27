import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    // Notifications are not supported on web
    if (kIsWeb) return;
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Initialize Timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _openPath(payload);
    }
  }

  Future<void> _openPath(String path) async {
    try {
      await OpenFilex.open(path);
    } catch (_) {}
  }

  Future<void> showExportNotification({
    required String fileName,
    required String exportFormat,
    required String filePath,
  }) async {
    // No-op on web
    if (kIsWeb) return;

    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'smartscan_export',
      'Export Notifications',
      channelDescription: 'Notifications after file export',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Export Successful ✓',
      body: '$fileName saved as $exportFormat — Tap to open location',
      notificationDetails: platformDetails,
      payload: filePath,
    );
  }

  Future<void> scheduleDateReminder({
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb) return;
    await initialize();

    // Ensure the date is in the future
    if (scheduledDate.isBefore(DateTime.now())) {
      // If it's today but time passed, or past date, don't schedule
      // or schedule for 1 minute from now for demo purposes? 
      // Let's just return for now.
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'smartscan_reminders',
      'Document Reminders',
      channelDescription: 'Reminders for dates detected in scans',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.zonedSchedule(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000) + 1,
      title: 'Reminder: $title',
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showScannerNotification() async {
    if (kIsWeb) return;
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'scanner_ongoing',
      'Scanner Activity',
      channelDescription: 'Keeps the app alive during document scanning',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true, // This is key for persistence
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      id: 999,
      title: 'SmartScan: Scanner Active',
      body: 'Camera open — app processing in background',
      notificationDetails: platformDetails,
    );
  }

  Future<void> cancelScannerNotification() async {
    if (kIsWeb) return;
    await _plugin.cancel(id: 999);
  }
}
