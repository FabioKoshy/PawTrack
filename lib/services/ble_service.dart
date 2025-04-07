import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _dataCharacteristic;
  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String DATA_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // Stream controller for satellite count updates
  final _satelliteCountController = StreamController<int>.broadcast();
  Stream<int> get satelliteCountStream => _satelliteCountController.stream;

  // Stream controller for connection status
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  // Flag to track if we're scanning
  bool _isScanning = false;

  // Flag to track if we've sufficient satellites
  bool _hasSufficientSatellites = false;
  bool get hasSufficientSatellites => _hasSufficientSatellites;

  // Stream subscription for characteristic value changes
  StreamSubscription? _characteristicSubscription;

  // Function to start scanning for ESP32 devices
  Future<List<BluetoothDevice>> startScan({Duration? timeout}) async {
    if (_isScanning) {
      return [];
    }

    _isScanning = true;
    List<BluetoothDevice> espDevices = [];

    // Start scanning
    try {
      // Make sure Bluetooth is on
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception("Bluetooth not supported on this device");
      }

      if (await FlutterBluePlus.isAvailable == false) {
        throw Exception("Bluetooth not available");
      }

      // Clear any old scan results
      await FlutterBluePlus.cancelWhenScanComplete;

      // Listen for scan results
      var subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.platformName.contains("ESP32_PetTracker")) {
            if (!espDevices.contains(result.device)) {
              espDevices.add(result.device);
            }
          }
        }
      });

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout ?? const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      // Wait for scan to complete
      await FlutterBluePlus.isScanning.first;
      await subscription.cancel();

    } catch (e) {
      print("Error scanning for BLE devices: $e");
    } finally {
      _isScanning = false;
    }

    return espDevices;
  }

  // Function to connect to an ESP32 device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      // Disconnect from any existing devices
      if (_connectedDevice != null) {
        await disconnect();
      }

      // Connect to the device
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      _connectionStatusController.add(true);

      // Discover services after connecting
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == DATA_CHAR_UUID) {
              _dataCharacteristic = characteristic;

              // Set up notification for satellite updates
              await characteristic.setNotifyValue(true);

              // Subscribe to value changes
              _characteristicSubscription = characteristic.lastValueStream.listen(_onDataReceived);

              break;
            }
          }
        }
      }

      // Save the device ID to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_connected_device', device.remoteId.toString());

      return true;
    } catch (e) {
      print("Error connecting to device: $e");
      _connectionStatusController.add(false);
      return false;
    }
  }

  // Function to disconnect from the ESP32 device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        // Cancel the characteristic subscription
        await _characteristicSubscription?.cancel();
        _characteristicSubscription = null;

        // Disconnect from the device
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _dataCharacteristic = null;
        _connectionStatusController.add(false);
      } catch (e) {
        print("Error disconnecting from device: $e");
      }
    }
  }

  // Function to handle data received from the ESP32
  void _onDataReceived(List<int> data) {
    try {
      // Convert the received data to a string
      String receivedData = utf8.decode(data);

      // Check if the data contains satellite information
      if (receivedData.contains("satellites")) {
        // Parse the number of satellites
        RegExp regExp = RegExp(r'(\d+)');
        Match? match = regExp.firstMatch(receivedData);

        if (match != null) {
          int satelliteCount = int.parse(match.group(1)!);
          _satelliteCountController.add(satelliteCount);

          // Update sufficient satellites flag
          _hasSufficientSatellites = satelliteCount >= 4;
        }
      }
    } catch (e) {
      print("Error processing received data: $e");
    }
  }

  // Send WiFi credentials to ESP32
  Future<bool> sendWiFiCredentials(String ssid, String password) async {
    if (_connectedDevice == null || _dataCharacteristic == null) {
      return false;
    }

    try {
      // Format: "WIFI:SSID,PASSWORD"
      String wifiData = "WIFI:$ssid,$password";
      List<int> bytes = utf8.encode(wifiData);

      await _dataCharacteristic!.write(bytes);
      return true;
    } catch (e) {
      print("Error sending WiFi credentials: $e");
      return false;
    }
  }

  // Get currently connected device
  BluetoothDevice? getConnectedDevice() {
    return _connectedDevice;
  }

  // Check if a device is connected
  bool isConnected() {
    return _connectedDevice != null;
  }

  // Get the ESPs that are saved in the app
  Future<List<String>> getSavedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('saved_esp_devices') ?? [];
  }

  // Save a new ESP device
  Future<void> saveDevice(String deviceId, String deviceName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedDevices = prefs.getStringList('saved_esp_devices') ?? [];

    // Store in format "id:name"
    savedDevices.add("$deviceId:$deviceName");
    await prefs.setStringList('saved_esp_devices', savedDevices);
  }

  // Clean up resources
  void dispose() {
    _characteristicSubscription?.cancel();
    _satelliteCountController.close();
    _connectionStatusController.close();
    disconnect();
  }
}