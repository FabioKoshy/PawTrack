import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/models/pet.dart';
import 'package:pawtrack/services/ble_service.dart';
import 'package:pawtrack/services/wifi_config_service.dart';
import 'package:pawtrack/services/pet_service.dart';
import 'package:pawtrack/pages/location_tracker_page.dart';

class GpsSetupPage extends StatefulWidget {
  final Pet pet;

  const GpsSetupPage({super.key, required this.pet});

  @override
  State<GpsSetupPage> createState() => _GpsSetupPageState();
}

class _GpsSetupPageState extends State<GpsSetupPage> with SingleTickerProviderStateMixin {
  final BleService _bleService = BleService();
  final WiFiConfigService _wifiService = WiFiConfigService();
  final PetService _petService = PetService();

  int _satelliteCount = 0;
  bool _isConnected = false;
  bool _wifiSent = false;
  bool _calibrationComplete = false;
  String _statusMessage = 'Connecting to ESP32...';

  // Animation controller for the progress indicator
  late AnimationController _animationController;

  // For the stepper
  int _currentStep = 0;

  StreamSubscription? _satelliteSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _wifiStatusSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for progress indicators
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start listening for BLE status updates
    _connectionSubscription = _bleService.connectionStatusStream.listen((connected) {
      setState(() {
        _isConnected = connected;
        if (connected) {
          _statusMessage = 'Connected to ESP32. Point the GPS antenna towards clear sky.';
          _currentStep = 1;
        } else {
          _statusMessage = 'Disconnected from ESP32. Please reconnect.';
          _currentStep = 0;
        }
      });
    });

    // Listen for satellite count updates
    _satelliteSubscription = _bleService.satelliteCountStream.listen((count) {
      setState(() {
        _satelliteCount = count;

        if (count >= 4 && !_calibrationComplete) {
          _statusMessage = 'GPS calibrated successfully! ESP32 is ready for use.';
          _calibrationComplete = true;
          _currentStep = 3;
        } else if (count > 0) {
          _statusMessage = 'Detecting satellites: $count found. Need at least 4.';
          _currentStep = 2;
        }
      });
    });

    // Listen for WiFi status updates
    _wifiStatusSubscription = _wifiService.wifiStatusStream.listen((status) {
      setState(() {
        _statusMessage = status;
        if (status.contains('WiFi credentials sent successfully')) {
          _wifiSent = true;
        }
      });
    });

    // Auto-connect to the ESP32 if we're not already connected
    if (!_bleService.isConnected()) {
      _connectToESP();
    } else {
      setState(() {
        _isConnected = true;
        _statusMessage = 'Already connected to ESP32. Point the GPS antenna towards clear sky.';
        _currentStep = 1;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _satelliteSubscription?.cancel();
    _connectionSubscription?.cancel();
    _wifiStatusSubscription?.cancel();
    super.dispose();
  }

  // Connect to the ESP32 device
  Future<void> _connectToESP() async {
    setState(() {
      _statusMessage = 'Scanning for ESP32 devices...';
    });

    try {
      final devices = await _bleService.startScan();

      if (devices.isEmpty) {
        setState(() {
          _statusMessage = 'No ESP32 devices found. Make sure the device is powered on and nearby.';
        });
        return;
      }

      // Connect to the first ESP32 device found
      setState(() {
        _statusMessage = 'Connecting to ${devices[0].platformName}...';
      });

      final connected = await _bleService.connectToDevice(devices[0]);

      if (!connected) {
        setState(() {
          _statusMessage = 'Failed to connect to ESP32. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  // Send WiFi credentials to the ESP32
  Future<void> _sendWiFiCredentials() async {
    final currentSSID = await _wifiService.getCurrentWifiSSID();

    if (currentSSID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to detect current WiFi network. Please make sure WiFi is enabled.')),
      );
      return;
    }

    // Show WiFi password dialog
    final password = await _showWiFiPasswordDialog(currentSSID);

    if (password != null) {
      await _wifiService.sendWiFiCredentialsToESP(currentSSID, password);
    }
  }

  // Show dialog to get WiFi password
  Future<String?> _showWiFiPasswordDialog(String ssid) async {
    final TextEditingController passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('WiFi Password for $ssid'),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(
            hintText: 'Enter WiFi password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  // Complete the setup and navigate to the location tracker
  void _completeSetup() {
    // Update the pet to mark GPS as calibrated
    _petService.updatePet(
      widget.pet.id,
      isGpsCalibrated: true,
    );

    // Navigate to the location tracker page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LocationTrackerPage(petId: widget.pet.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Setup'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pet name and progress indicator
                      Text(
                        '${widget.pet.name}\'s GPS Setup',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),

                      // Stepper for setup process
                      Expanded(
                        child: Stepper(
                          currentStep: _currentStep,
                          controlsBuilder: (context, details) => Container(),
                          steps: [
                            Step(
                              title: const Text('Connect to Device'),
                              content: Column(
                                children: [
                                  _isConnected
                                      ? const Icon(Icons.check_circle, color: Colors.green, size: 48)
                                      : _buildConnectingAnimation(),
                                  const SizedBox(height: 10),
                                  Text(
                                    _isConnected
                                        ? 'Connected to ESP32 successfully!'
                                        : 'Connecting to ESP32...',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  if (!_isConnected) ...[
                                    const SizedBox(height: 15),
                                    CustomButton(
                                      text: 'Retry Connection',
                                      icon: Icons.refresh,
                                      onTap: _connectToESP,
                                    ),
                                  ],
                                ],
                              ),
                              isActive: _currentStep == 0,
                              state: _isConnected
                                  ? StepState.complete
                                  : StepState.indexed,
                            ),
                            Step(
                              title: const Text('Point to Clear Sky'),
                              content: Column(
                                children: [
                                  _buildSkyPointingAnimation(),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Point the GPS antenna towards a clear sky to detect satellites.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              isActive: _currentStep == 1,
                              state: _satelliteCount > 0
                                  ? StepState.complete
                                  : StepState.indexed,
                            ),
                            Step(
                              title: const Text('Detecting Satellites'),
                              content: Column(
                                children: [
                                  _buildSatelliteCountWidget(),
                                  const SizedBox(height: 10),
                                  Text(
                                    _satelliteCount >= 4
                                        ? 'Great! Sufficient satellites detected.'
                                        : 'Detecting satellites. Need at least 4 satellites for accurate tracking.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  if (_satelliteCount > 0 && _satelliteCount < 4) ...[
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Move to an area with better sky visibility if progress is slow.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              isActive: _currentStep == 2,
                              state: _satelliteCount >= 4
                                  ? StepState.complete
                                  : StepState.indexed,
                            ),
                            Step(
                              title: const Text('Ready to Use'),
                              content: Column(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'GPS calibration complete! The device is now ready to be placed on the harness.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 20),
                                  if (!_wifiSent) ...[
                                    CustomButton(
                                      text: 'Send WiFi Credentials',
                                      icon: Icons.wifi,
                                      onTap: _sendWiFiCredentials,
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  CustomButton(
                                    text: 'Continue to Location Tracking',
                                    icon: Icons.navigate_next,
                                    onTap: _completeSetup,
                                  ),
                                ],
                              ),
                              isActive: _currentStep == 3,
                              state: _calibrationComplete
                                  ? StepState.complete
                                  : StepState.indexed,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Status bar at the bottom
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for displaying satellite count
  Widget _buildSatelliteCountWidget() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        border: Border.all(
          color: _satelliteCount >= 4
              ? Colors.green
              : Theme.of(context).colorScheme.primary,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _satelliteCount.toString(),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: _satelliteCount >= 4
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const Text(
            'satellites',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Animation for connecting to ESP32
  Widget _buildConnectingAnimation() {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(8),
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // Animation for pointing to sky
  Widget _buildSkyPointingAnimation() {
    return SizedBox(
      height: 200,
      width: 200,
      child: SvgPicture.asset(
        'assets/images/gps_calibration.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}