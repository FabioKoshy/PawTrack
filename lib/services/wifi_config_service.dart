import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawtrack/services/ble_service.dart';

class WiFiConfigService {
  static final WiFiConfigService _instance = WiFiConfigService._internal();
  factory WiFiConfigService() => _instance;
  WiFiConfigService._internal();

  final NetworkInfo _networkInfo = NetworkInfo();
  final BleService _bleService = BleService();
  final Connectivity _connectivity = Connectivity();

  // Stream controller for WiFi status updates
  final _wifiStatusController = StreamController<String>.broadcast();
  Stream<String> get wifiStatusStream => _wifiStatusController.stream;

  // Get current WiFi SSID
  Future<String?> getCurrentWifiSSID() async {
    try {
      return await _networkInfo.getWifiName();
    } catch (e) {
      print("Error getting WiFi SSID: $e");
      return null;
    }
  }

  // Get saved WiFi networks
  Future<List<Map<String, String>>> getSavedNetworks() async {
    final prefs = await SharedPreferences.getInstance();
    final networksJson = prefs.getStringList('saved_wifi_networks') ?? [];

    List<Map<String, String>> networks = [];
    for (String network in networksJson) {
      final parts = network.split(':');
      if (parts.length == 2) {
        networks.add({
          'ssid': parts[0],
          'password': parts[1],
        });
      }
    }

    return networks;
  }

  // Save a new WiFi network
  Future<void> saveNetwork(String ssid, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> networks = prefs.getStringList('saved_wifi_networks') ?? [];

    // Check if network already exists
    bool exists = false;
    for (int i = 0; i < networks.length; i++) {
      if (networks[i].startsWith('$ssid:')) {
        networks[i] = '$ssid:$password';
        exists = true;
        break;
      }
    }

    // Add network if it doesn't exist
    if (!exists) {
      networks.add('$ssid:$password');
    }

    await prefs.setStringList('saved_wifi_networks', networks);
  }

  // Remove a saved WiFi network
  Future<void> removeNetwork(String ssid) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> networks = prefs.getStringList('saved_wifi_networks') ?? [];

    networks.removeWhere((network) => network.startsWith('$ssid:'));
    await prefs.setStringList('saved_wifi_networks', networks);
  }

  // Send WiFi credentials to the ESP32
  Future<bool> sendWiFiCredentialsToESP(String ssid, String password) async {
    if (!_bleService.isConnected()) {
      _wifiStatusController.add('Not connected to ESP32');
      return false;
    }

    _wifiStatusController.add('Sending WiFi credentials to ESP32...');
    bool result = await _bleService.sendWiFiCredentials(ssid, password);

    if (result) {
      _wifiStatusController.add('WiFi credentials sent successfully');
      // Save the network if it was successful
      await saveNetwork(ssid, password);
    } else {
      _wifiStatusController.add('Failed to send WiFi credentials');
    }

    return result;
  }

  // Check current WiFi connection status
  Future<bool> isWifiConnected() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult == ConnectivityResult.wifi;
  }

  // Listen for WiFi status changes
  void startWifiStatusListener() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.wifi) {
        _wifiStatusController.add('Connected to WiFi');
      } else {
        _wifiStatusController.add('Disconnected from WiFi');
      }
    });
  }

  // Clean up resources
  void dispose() {
    _wifiStatusController.close();
  }
}