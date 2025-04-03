import 'package:flutter/material.dart';
import 'package:pawtrack/services/notification_service.dart';

import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<String> notifications = [];

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    _listenToHeartRate();
  }

  void _listenToHeartRate() {
    getHeartRateStream().listen((int heartRate) {
      if (heartRate < 50 || heartRate > 100) {
        NotificationService.showNotification("Heart Rate Alert", "Heart rate is $heartRate BPM!");
        setState(() {
          notifications.add("Heart rate alert: $heartRate BPM");
        });
      }
    });
  }

  Stream<int> getHeartRateStream() async* {
    List<int> heartRates = [65, 72, 110, 45, 85, 125, 60]; // Example values
    for (int rate in heartRates) {
      yield rate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: notifications.isEmpty
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
    );
  }
}
