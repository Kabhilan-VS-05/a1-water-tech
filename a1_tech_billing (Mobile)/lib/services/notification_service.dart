import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  final StreamController<String?> _onTapController = StreamController<String?>.broadcast();
  Stream<String?> get onTapStream => _onTapController.stream;

  String? initialPayload;

  Future<void> initialize() async {
    if (_initialized) return;

    // VERY IMPORTANT: The icon must perfectly match the one in AndroidManifest.xml
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _onTapController.add(details.payload);
      },
    );

    // CRITICAL FOR ANDROID 13/14/15: Explicitly create the channel so it registers properly with the OS
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'a1_water_tech_channel',
          'A1 Water Tech Notifications',
          description: 'Notifications for new orders and bookings',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    // Capture notification that launched the app from terminated state
    final NotificationAppLaunchDetails? launchDetails = 
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      initialPayload = launchDetails.notificationResponse?.payload;
    }
    
    _initialized = true;
  }

  Future<void> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    // CRITICAL: Android requires a positive 32-bit integer for notification IDs.
    // Dart's hashCode can sometimes be negative or exceed 32-bits, causing silent failures!
    final int safeId = id.abs() & 0x7FFFFFFF;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'a1_water_tech_channel',
      'A1 Water Tech Notifications',
      channelDescription: 'Notifications for new orders and bookings',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      safeId,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
