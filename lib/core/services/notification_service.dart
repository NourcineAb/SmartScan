import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';

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
}
