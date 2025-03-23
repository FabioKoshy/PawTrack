import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  LatLng? geofenceCenter;
  double geofenceRadius = 1000.0;
  bool geofenceEnabled = false;
  String? petId;
  String? petName;
  Map<String, dynamic>? gpsData;
  bool wasInsideGeofence = true;
  StreamSubscription<DatabaseEvent>? _gpsSubscription;
  bool _isInitialized = false; // Track if notifications are initialized

  Future<void> initialize(String petId, String petName) async {
    this.petId = petId;
    this.petName = petName;

    // Initialize notifications if not already initialized
    if (!_isInitialized) {
      await _initializeNotifications();
      _isInitialized = true;
    }

    // Load geofence settings
    await _loadGeofenceSettings();

    // Start listening to GPS data
    _listenToGpsData();
  }

  Future<void> _initializeNotifications() async {
    // Define the notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'geofence_channel', // Same as used in _showNotification
      'Geofence Alerts',
      description: 'Notifications for geofence events',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Initialize the plugin with Android settings
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidInitSettings);

    // Create the notification channel on Android
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print("Notification tapped: ${response.payload}");
      },
    );
  }

  Future<void> _loadGeofenceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    geofenceEnabled = prefs.getBool('geofenceEnabled_$petId') ?? false;
    final centerLat = prefs.getDouble('geofenceCenterLat_$petId');
    final centerLon = prefs.getDouble('geofenceCenterLon_$petId');
    if (centerLat != null && centerLon != null) {
      geofenceCenter = LatLng(centerLat, centerLon);
    }
    geofenceRadius = prefs.getDouble('geofenceRadius_$petId') ?? 1000.0;
  }

  void _listenToGpsData() {
    final petGpsRef = FirebaseDatabase.instance.ref('gpslocation');
    _gpsSubscription = petGpsRef.onValue.listen((event) async {
      if (event.snapshot.exists) {
        gpsData = Map<String, dynamic>.from(event.snapshot.value as Map);
        _checkGeofence();
      }
    });
  }

  void _checkGeofence() async {
    if (!geofenceEnabled || geofenceCenter == null || gpsData == null) return;

    final petLat = gpsData!['stats']?['latitude']?.toDouble();
    final petLon = gpsData!['stats']?['longitude']?.toDouble();

    if (petLat == null || petLon == null) return;

    final distance = Geolocator.distanceBetween(
      geofenceCenter!.latitude,
      geofenceCenter!.longitude,
      petLat,
      petLon,
    );

    final isInsideGeofence = distance <= geofenceRadius;

    // Check for geofence crossing
    if (wasInsideGeofence && !isInsideGeofence) {
      // Pet has exited the geofence
      final message = "$petName has exited the geofence!";
      await _showNotification("Geofence Alert", message);
      await _saveNotification("geofence", message);
    } else if (!wasInsideGeofence && isInsideGeofence) {
      // Pet has entered the geofence
      final message = "$petName has entered the geofence!";
      await _showNotification("Geofence Alert", message);
      await _saveNotification("geofence", message);
    }

    wasInsideGeofence = isInsideGeofence;
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Alerts',
      channelDescription: 'Notifications for geofence events',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      details,
    );
  }

  Future<void> _saveNotification(String type, String message) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationList = prefs.getStringList('notifications') ?? [];
    final timestamp = DateTime.now().toString();
    notificationList.add('$type|$message|$timestamp');
    await prefs.setStringList('notifications', notificationList);
  }

  void stop() {
    _gpsSubscription?.cancel();
  }
}