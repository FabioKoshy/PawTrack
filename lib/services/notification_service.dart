import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Initialize FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize notification settings
  Future<void> initialize(BuildContext context) async {
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings (optional)
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // Combine platform-specific settings
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        // Handle notification tap
        if (context.mounted) {
          _handleNotificationTap(notificationResponse, context);
        }
      },
    );

    // Request notification permissions for iOS
    await _requestIOSPermissions();
  }

  // Request iOS notification permissions
  Future<void> _requestIOSPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Handle notification tap
  void _handleNotificationTap(
      NotificationResponse notificationResponse,
      BuildContext context
      ) {
    // Implement custom navigation logic based on notification payload
    switch (notificationResponse.payload) {
      case 'heart_rate':
      // Navigate to heart rate page
        if (context.mounted) {
          Navigator.pushNamed(context, '/heart_rate');
        }
        break;
      case 'location':
      // Navigate to location tracking page
        if (context.mounted) {
          Navigator.pushNamed(context, '/location_tracker');
        }
        break;
      default:
      // Default navigation or do nothing
        break;
    }
  }

  // Show a basic notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Android notification details
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'pawtrack_channel', // Channel ID
      'PawTrack Notifications', // Channel Name
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    // iOS notification details (optional)
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails(
      presentSound: true,
      presentBadge: true,
    );

    // Combine platform-specific details
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Show a periodic notification
  Future<void> showPeriodicNotification({
    required String title,
    required String body,
    required RepeatInterval repeatInterval,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'periodic_channel',
      'Periodic Notifications',
      importance: Importance.low,
      priority: Priority.low,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.periodicallyShow(
      1, // Notification ID
      title,
      body,
      repeatInterval,
      platformChannelSpecifics,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}