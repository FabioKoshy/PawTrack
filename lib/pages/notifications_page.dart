import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  List<String> notifications = [];

  // Simulated heartbeat stream (Replace with real data source)
  Stream<int> getHeartRateStream() async* {
    List<int> heartRates = [65, 72, 110, 45, 85, 125, 60]; // Example values
    for (int rate in heartRates) {
      await Future.delayed(Duration(seconds: 3)); // Simulate data updates
      yield rate;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _listenToHeartRate();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidInitSettings);

    await _notificationsPlugin.initialize(initSettings);
  }

  void _listenToHeartRate() {
    getHeartRateStream().listen((int heartRate) {
      if (heartRate < 50 || heartRate > 100) {
        _showNotification(heartRate);
        setState(() {
          notifications.add("Heart rate alert: $heartRate BPM");
        });
      }
    });
  }

  Future<void> _showNotification(int heartRate) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'heart_rate_channel',
      'Heart Rate Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Heart Rate Alert',
      'Heart rate is $heartRate BPM!',
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Heart Rate Notifications",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: notifications.isEmpty
                ? const Center(child: Text("No notifications yet"))
                : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(notifications[index]),
                  leading: const Icon(Icons.warning, color: Colors.red),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

