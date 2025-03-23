import 'package:flutter/material.dart';
// Comment out this import for now
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Comment out the notifications plugin
  // final FlutterLocalNotificationsPlugin _notificationsPlugin =
  //   FlutterLocalNotificationsPlugin();

  List<String> notifications = [];

  // Simulated heartbeat stream (Replace with real data source)
  Stream<int> getHeartRateStream() async* {
    List<int> heartRates = [65, 72, 110, 45, 85, 125, 60]; // Example values
    for (int rate in heartRates) {
      await Future.delayed(const Duration(seconds: 2)); // Add delay for simulation
      yield rate;
    }
  }

  @override
  void initState() {
    super.initState();
    // _initializeNotifications();
    _listenToHeartRate();
  }

  // Commented out for now
  // void _initializeNotifications() async {
  //   const AndroidInitializationSettings androidInitSettings =
  //     AndroidInitializationSettings('@mipmap/ic_launcher');
  //   const InitializationSettings initSettings =
  //     InitializationSettings(android: androidInitSettings);
  //   await _notificationsPlugin.initialize(initSettings);
  // }

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

  // Simplified to just a console log for now
  Future<void> _showNotification(int heartRate) async {
    // Debug output instead of showing a real notification
    debugPrint('Would show notification: Heart rate is $heartRate BPM!');

    // Commented out actual notification logic
    // const AndroidNotificationDetails androidDetails =
    //   AndroidNotificationDetails(
    //     'heart_rate_channel',
    //     'Heart Rate Alerts',
    //     importance: Importance.high,
    //     priority: Priority.high,
    //   );
    // const NotificationDetails details =
    //   NotificationDetails(android: androidDetails);
    // await _notificationsPlugin.show(
    //   0,
    //   'Heart Rate Alert',
    //   'Heart rate is $heartRate BPM!',
    //   details,
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(50), // Fixed opacity issue
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