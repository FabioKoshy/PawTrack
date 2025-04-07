import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'wifi_config_page.dart'; // Added missing import

class BluetoothPairingPage extends StatefulWidget {
  const BluetoothPairingPage({super.key});

  @override
  _BluetoothPairingPageState createState() => _BluetoothPairingPageState();
}

class _BluetoothPairingPageState extends State<BluetoothPairingPage> {
  bool isScanning = false;
  bool isConnecting = false;
  String pairingStatus = 'Not Paired';
  List<ScanResult> scanResults = [];

  @override
  void initState() {
    super.initState();
    _requestBluetoothPermissions();
  }

  Future<bool> _requestBluetoothPermissions() async {
    PermissionStatus scanStatus = await Permission.bluetoothScan.request();
    PermissionStatus connectStatus = await Permission.bluetoothConnect.request();
    PermissionStatus locationStatus = await Permission.location.request();

    if (scanStatus.isGranted && connectStatus.isGranted && locationStatus.isGranted) {
      return true;
    } else if (scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied || locationStatus.isPermanentlyDenied) {
      _showPermissionSettingsDialog();
      return false;
    }
    return false;
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Please enable Bluetooth and Location permissions in settings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _startScan() async {
    if (!(await _requestBluetoothPermissions())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions denied'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!(await FlutterBluePlus.isOn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please turn on Bluetooth'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      isScanning = true;
      scanResults.clear();
      pairingStatus = 'Not Paired';
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10)).then((_) {
      setState(() => isScanning = false);
    });

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results.where((r) => r.device.name.isNotEmpty).toList(); // Show all named devices
      });
    });
  }

  void _attemptPairing(BluetoothDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pair Device'),
        content: Text('Would you like to pair with "${device.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _connectToDevice(device);
            },
            child: const Text('Pair'),
          ),
        ],
      ),
    );
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
      pairingStatus = 'Waiting for Bluetooth pairing...';
    });

    try {
      await device.connect();
      setState(() {
        pairingStatus = 'Bluetooth pairing: Success';
        isConnecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device paired successfully')),
      );
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WifiConfigPage(device: device)),
      );
      if (result != null) {
        Navigator.pop(context, result); // Return the full result map
      }
    } catch (e) {
      setState(() {
        pairingStatus = 'Bluetooth pairing: Failed, please try again ($e)';
        isConnecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pairing failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Pairing")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Scan for Available Devices",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isScanning ? null : _startScan,
              child: Text(isScanning ? 'Scanning...' : 'Start Scan'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  final result = scanResults[index];
                  return ListTile(
                    title: Text(result.device.name),
                    subtitle: Text(result.device.id.toString()),
                    onTap: () => _attemptPairing(result.device),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Pairing Status: "),
                if (isConnecting) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
                Text(
                  pairingStatus,
                  style: TextStyle(
                    color: pairingStatus.contains('Success') ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}