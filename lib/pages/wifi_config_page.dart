import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class WifiConfigPage extends StatefulWidget {
  final BluetoothDevice device;

  const WifiConfigPage({super.key, required this.device});

  @override
  _WifiConfigPageState createState() => _WifiConfigPageState();
}

class _WifiConfigPageState extends State<WifiConfigPage> {
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isConnecting = false;
  String connectionStatus = 'Not Connected';

  @override
  void initState() {
    super.initState();
    // Request a larger MTU size when the page is initialized
    _requestMtu();
  }

  Future<void> _requestMtu() async {
    try {
      await widget.device.requestMtu(128); // Request an MTU of 128 bytes
      print("MTU requested: 128 bytes");
    } catch (e) {
      print("Error requesting MTU: $e");
    }
  }

  void _sendWifiCredentials() async {
    setState(() {
      isConnecting = true;
      connectionStatus = 'Connecting to Wi-Fi...';
    });

    try {
      List<BluetoothService> services = await widget.device.discoverServices();
      BluetoothCharacteristic? wifiChar;

      for (BluetoothService service in services) {
        if (service.uuid.toString() == "4fafc201-1fb5-459e-8fcc-c5c9c331914b") {
          for (BluetoothCharacteristic char in service.characteristics) {
            if (char.uuid.toString() == "12345678-1234-5678-1234-567812345678") {
              wifiChar = char;
              break;
            }
          }
        }
        if (wifiChar != null) break;
      }

      if (wifiChar == null) {
        throw 'Wi-Fi characteristic not found';
      }

      String credentials =
          "SSID:${ssidController.text},PWD:${passwordController.text},USER:${userController.text}";
      print("Sending credentials: $credentials");
      print("Credentials length: ${credentials.length} bytes");

      // Convert the string to bytes
      List<int> credentialsBytes = credentials.codeUnits;
      print("Credentials bytes: $credentialsBytes");

      // Write the credentials to the characteristic
      await wifiChar.write(credentialsBytes, withoutResponse: false);

      await wifiChar.setNotifyValue(true);
      wifiChar.value.listen((value) {
        String status = String.fromCharCodes(value);
        setState(() {
          connectionStatus = status;
          isConnecting = false;
        });
        if (status == 'Connected') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wi-Fi Connected')),
          );
          Navigator.pop(context, {'status': 'Connected', 'ssid': ssidController.text});
        } else if (status == 'Failed') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wi-Fi Connection Failed'), backgroundColor: Colors.red),
          );
          Navigator.pop(context, {'status': 'Failed', 'ssid': null});
        }
      });
    } catch (e) {
      setState(() {
        connectionStatus = 'Failed: $e';
        isConnecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      Navigator.pop(context, {'status': 'Failed', 'ssid': null});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wi-Fi Configuration")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter Wi-Fi Details for ESP32_PetTracker",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ssidController,
              decoration: const InputDecoration(
                labelText: "Wi-Fi SSID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: userController,
              decoration: const InputDecoration(
                labelText: "Wi-Fi User (Optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Wi-Fi Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendWifiCredentials,
              child: const Text("Send Credentials"),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Connection Status: "),
                if (isConnecting) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ] else ...[
                  Text(
                    connectionStatus,
                    style: TextStyle(
                      color: connectionStatus == 'Connected' ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ssidController.dispose();
    userController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}