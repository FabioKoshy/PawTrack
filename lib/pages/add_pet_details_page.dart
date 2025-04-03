import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/components/custom_text_field.dart';
import 'package:pawtrack/services/pet_service.dart';

class AddPetDetailsPage extends StatefulWidget {
  const AddPetDetailsPage({super.key});

  @override
  State<AddPetDetailsPage> createState() => _AddPetDetailsPageState();
}

class _AddPetDetailsPageState extends State<AddPetDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  String? selectedDeviceId;
  final PetService _petService = PetService();
  List<BluetoothDevice> foundDevices = [];

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    final locationStatus = await Permission.location.request();

    if (!locationStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required for BLE scan.')),
      );
      return;
    }

    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable Location Services (GPS) to scan for BLE devices.')),
      );
      return;
    }

    _scanForDevices();
  }

  void _scanForDevices() async {
    foundDevices.clear();

    // Stop previous scan if active
    await FlutterBluePlus.stopScan();

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        final device = r.device;
        final name = device.platformName;

        if (name == "ESP32_PetTracker" &&
            !foundDevices.any((d) => d.remoteId == device.remoteId)) {
          print("✅ Found ESP32: ${device.platformName} (${device.remoteId})");
          setState(() {
            foundDevices.add(device);
          });
        }
      }
    });
  }

  void _addPet() async {
    final name = nameController.text.trim();
    if (name.isEmpty || selectedDeviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    await _petService.addPet(name, selectedDeviceId!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Pet Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              hintText: "Pet Name",
              obscureText: false,
              controller: nameController,
              validator: (value) => value!.isEmpty ? 'Pet name is required' : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedDeviceId,
              hint: const Text("Select Bluetooth Device"),
              items: foundDevices.map((device) {
                return DropdownMenuItem<String>(
                  value: device.remoteId.str,
                  child: Text(device.platformName),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedDeviceId = value),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(text: "Add Pet", onTap: _addPet),
          ],
        ),
      ),
    );
  }
}
