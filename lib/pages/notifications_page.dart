import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pawtrack/services/pet_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Create a notification service class that will be initialized with the app
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final PetService _petService = PetService();
  bool isInitialized = false;

  Future<void> initialize(BuildContext context) async {
    if (isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Navigate to notifications page when notification is tapped
        if (context.mounted) {
          Navigator.pushNamed(context, '/notifications');
        }
      },
    );

    // Start listening for heart rate alerts
    _startListeningForAlerts();

    isInitialized = true;
  }

  Future<void> _startListeningForAlerts() async {
    try {
      final pets = await _petService.getPets();

      for (final pet in pets) {
        _listenForHeartRateAlerts(pet.id, pet.name);
      }
    } catch (e) {
      debugPrint("Error setting up notifications: $e");
    }
  }

  void _listenForHeartRateAlerts(String petId, String petName) {
    final statusRef = FirebaseDatabase.instance.ref("petStatus/$petId/heartRate/status");
    final thresholdRef = FirebaseDatabase.instance.ref("settings/$petId/heartRate/thresholds");
    final currentBpmRef = FirebaseDatabase.instance.ref("heartrate/current_bpm");

    // Listen for status changes
    statusRef.onValue.listen((event) {
      final status = event.snapshot.value as String?;

      if (status == null || status == "normal") {
        return;
      }

      // Get threshold values and current BPM to include in the alert
      Future.wait([
        thresholdRef.get(),
        currentBpmRef.get(),
      ]).then((results) {
        final thresholdSnapshot = results[0];
        final bpmSnapshot = results[1];

        int minThreshold = 60;
        int maxThreshold = 140;
        double currentBpm = 0;

        if (thresholdSnapshot.exists) {
          final data = thresholdSnapshot.value as Map<dynamic, dynamic>;
          minThreshold = data['min'] ?? 60;
          maxThreshold = data['max'] ?? 140;
        }

        if (bpmSnapshot.exists) {
          currentBpm = (bpmSnapshot.value as num).toDouble();
        }

        // Create alert message based on the actual status and BPM
        String alertMessage;
        if (status == "tooLow" && currentBpm < minThreshold) {
          alertMessage = "Heart rate is ${currentBpm.toStringAsFixed(1)} BPM (below minimum threshold of $minThreshold BPM)";
        } else if (status == "tooHigh" && currentBpm > maxThreshold) {
          alertMessage = "Heart rate is ${currentBpm.toStringAsFixed(1)} BPM (above maximum threshold of $maxThreshold BPM)";
        } else {
          // Handle potential edge case where status and value don't match
          alertMessage = "Heart rate is ${currentBpm.toStringAsFixed(1)} BPM";
        }

        // Send a phone notification
        _showNotification(
          petName: petName,
          title: "$petName's Heart Rate Alert",
          body: alertMessage,
          id: petId.hashCode,
        );
      });
    });
  }

  Future<void> _showNotification({
    required String petName,
    required String title,
    required String body,
    required int id,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'heart_rate_alerts',
      'Heart Rate Alerts',
      channelDescription: 'Important alerts about your pet\'s heart rate',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      color: Color(0xFFFF4081), // Pink color for the notification icon
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'pet_heart_rate_alert',
    );
  }
}

import 'package:pawtrack/services/notification_service.dart';

import '../services/notification_service.dart';


class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {

  final PetService _petService = PetService();
  final List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  List<String> notifications = [];


  @override
  void initState() {
    super.initState();

    // Initialize notification service in case it hasn't been done yet
    if (mounted) {
      NotificationService().initialize(context);
    }
    _loadPetsAndListenForAlerts();
  }

  Future<void> _loadPetsAndListenForAlerts() async {
    try {
      final pets = await _petService.getPets();

      if (pets.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      for (final pet in pets) {
        _listenForHeartRateAlerts(pet.id, pet.name);
      }

      if (mounted) {

    NotificationService.init();
    _listenToHeartRate();
  }

  void _listenToHeartRate() {
    getHeartRateStream().listen((int heartRate) {
      if (heartRate < 50 || heartRate > 100) {
        NotificationService.showNotification("Heart Rate Alert", "Heart rate is $heartRate BPM!");

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading pets: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _listenForHeartRateAlerts(String petId, String petName) {
    final statusRef = FirebaseDatabase.instance.ref("petStatus/$petId/heartRate/status");
    final thresholdRef = FirebaseDatabase.instance.ref("settings/$petId/heartRate/thresholds");
    final currentBpmRef = FirebaseDatabase.instance.ref("heartrate/current_bpm");

    // Listen for status changes
    statusRef.onValue.listen((event) {
      final status = event.snapshot.value as String?;

      if (status == null || status == "normal") {
        // Remove any existing heart rate alerts for this pet
        if (mounted) {
          setState(() {
            notifications.removeWhere((alert) =>
            alert['petId'] == petId && alert['type'] == 'heartRate');
          });
        }
        return;
      }

      // Get threshold values and current BPM to include in the alert
      Future.wait([
        thresholdRef.get(),
        currentBpmRef.get(),
      ]).then((results) {
        final thresholdSnapshot = results[0];
        final bpmSnapshot = results[1];

        int minThreshold = 60;
        int maxThreshold = 140;
        double currentBpm = 0;

        if (thresholdSnapshot.exists) {
          final data = thresholdSnapshot.value as Map<dynamic, dynamic>;
          minThreshold = data['min'] ?? 60;
          maxThreshold = data['max'] ?? 140;
        }

        if (bpmSnapshot.exists) {
          currentBpm = (bpmSnapshot.value as num).toDouble();
        }

        // Create alert message with double-check on the threshold logic
        String alertMessage;
        Color alertColor;
        IconData alertIcon;

        if (status == "tooLow" && currentBpm < minThreshold) {
          alertMessage = "Heart rate is ${currentBpm.toStringAsFixed(1)} BPM (below minimum threshold of $minThreshold BPM)";
          alertColor = Colors.blue;
          alertIcon = Icons.arrow_downward;
        } else if (status == "tooHigh" && currentBpm > maxThreshold) {
          alertMessage = "Heart rate is ${currentBpm.toStringAsFixed(1)} BPM (above maximum threshold of $maxThreshold BPM)";
          alertColor = Colors.red;
          alertIcon = Icons.arrow_upward;
        } else {
          // Handle potential edge case where status and value don't match
          alertMessage = "Heart rate is ${currentBpm.toStringAsFixed(1)} BPM";
          alertColor = Colors.orange;
          alertIcon = Icons.warning;
        }

        // Check if alert already exists
        final existingIndex = notifications.indexWhere((alert) =>
        alert['petId'] == petId && alert['type'] == 'heartRate');

        final now = DateTime.now();

        if (mounted) {
          setState(() {
            if (existingIndex >= 0) {
              // Update existing alert
              notifications[existingIndex] = {
                'petId': petId,
                'petName': petName,
                'type': 'heartRate',
                'message': alertMessage,
                'timestamp': now,
                'color': alertColor,
                'icon': alertIcon,
              };
            } else {
              // Add new alert
              notifications.add({
                'petId': petId,
                'petName': petName,
                'type': 'heartRate',
                'message': alertMessage,
                'timestamp': now,
                'color': alertColor,
                'icon': alertIcon,
              });
            }

            // Sort notifications by timestamp (newest first)
            notifications.sort((a, b) =>
                (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
          });
        }
      });
    });
  }


  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else {
      return "${difference.inDays}d ago";

  Stream<int> getHeartRateStream() async* {
    List<int> heartRates = [65, 72, 110, 45, 85, 125, 60]; // Example values
    for (int rate in heartRates) {
      yield rate;

    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(

      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Clear all notifications",
              onPressed: () {
                setState(() {
                  notifications.clear();
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              "No notifications",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];

          return Dismissible(
            key: Key('notification_${index}_${notification['timestamp'].toString()}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              color: Colors.red,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            onDismissed: (direction) {
              setState(() {
                notifications.removeAt(index);
              });
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: notification['color'],
                  width: 1.5,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: notification['color'],
                  child: Icon(
                    notification['icon'],
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  "${notification['petName']}'s Heart Rate Alert",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notification['message']),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification['timestamp']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      notifications.removeAt(index);
                    });
                  },
                ),
              ),
            ),

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
