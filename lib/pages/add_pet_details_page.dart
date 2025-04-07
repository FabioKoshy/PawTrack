import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/components/custom_text_field.dart';
import 'package:pawtrack/pages/gps_setup_page.dart';
import 'package:pawtrack/services/ble_service.dart';
import 'package:pawtrack/services/pet_service.dart';
import 'package:permission_handler/permission_handler.dart';

class AddPetDetailsPage extends StatefulWidget {
  const AddPetDetailsPage({super.key});

  @override
  State<AddPetDetailsPage> createState() => _AddPetDetailsPageState();
}

class _AddPetDetailsPageState extends State<AddPetDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  String? selectedDevice;
  File? _image;
  List<BluetoothDevice> _bleDevices = [];
  bool _isScanning = false;

  final PetService _petService = PetService();
  final BleService _bleService = BleService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _checkBluetoothPermissions();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkBluetoothPermissions() async {
    // For newer Android versions, we need both Bluetooth and location permissions
    if (await Permission.bluetooth.isDenied ||
        await Permission.bluetoothScan.isDenied ||
        await Permission.bluetoothConnect.isDenied ||
        await Permission.location.isDenied) {

      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.location.request();

      bool bluetoothDenied = await Permission.bluetooth.isDenied ||
          await Permission.bluetoothScan.isDenied ||
          await Permission.bluetoothConnect.isDenied;
      bool locationDenied = await Permission.location.isDenied;

      if (bluetoothDenied || locationDenied) {
        _showBluetoothPermissionDialog();
      } else {
        _scanForDevices();
      }
    } else {
      _scanForDevices();
    }
  }

  void _showBluetoothPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'Bluetooth and location permissions are required to scan for and connect to your PawTrack device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanForDevices() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _bleDevices = [];
    });

    try {
      List<BluetoothDevice> devices = await _bleService.startScan(timeout: const Duration(seconds: 5));

      setState(() {
        _bleDevices = devices;
        _isScanning = false;
      });
    } catch (e) {
      print("Error scanning for BLE devices: $e");
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _pickImage() async {
    PermissionStatus status = await Permission.photos.status;

    if (status.isPermanentlyDenied) {
      _showPermissionSettingsDialog();
      return;
    }

    if (status.isDenied) {
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission to access photos is required to select an image.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Photo access is required to select an image. Please enable it in your app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _addPet() async {
    if (nameController.text.isEmpty || selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields (Name and Bluetooth Device)')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      int? age;
      if (ageController.text.isNotEmpty) {
        age = int.tryParse(ageController.text);
        if (age == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Age must be a valid number'), backgroundColor: Colors.red),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      double? weight;
      if (weightController.text.isNotEmpty) {
        weight = double.tryParse(weightController.text);
        if (weight == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Weight must be a valid number'), backgroundColor: Colors.red),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Find the selected BLE device
      BluetoothDevice? deviceToConnect;
      for (var device in _bleDevices) {
        if (device.remoteId.toString() == selectedDevice) {
          deviceToConnect = device;
          break;
        }
      }

      if (deviceToConnect == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected device not found. Please try scanning again.'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Connect to the device
      bool connected = await _bleService.connectToDevice(deviceToConnect);
      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to the device. Please try again.'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Add the pet to Firestore
      final pet = await _petService.addPet(
        nameController.text.trim(),
        selectedDevice!,
        age: age,
        breed: breedController.text.isNotEmpty ? breedController.text : null,
        weight: weight,
        image: _image,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to the GPS setup page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GpsSetupPage(pet: pet),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add pet: $e'), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Pet Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet Image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: _image != null
                        ? ClipOval(
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      ),
                    )
                        : const Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pet Details Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pet Details",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pet Name
                    Text(
                      "Pet Name",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      hintText: "Enter pet name",
                      obscureText: false,
                      controller: nameController,
                      validator: (value) => value!.isEmpty ? 'Pet name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Pet Age
                    Text(
                      "Age (Optional)",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      hintText: "Enter age",
                      obscureText: false,
                      controller: ageController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Pet Breed
                    Text(
                      "Breed (Optional)",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      hintText: "Enter breed",
                      obscureText: false,
                      controller: breedController,
                    ),
                    const SizedBox(height: 16),

                    // Pet Weight
                    Text(
                      "Weight in kg (Optional)",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      hintText: "Enter weight",
                      obscureText: false,
                      controller: weightController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Bluetooth Device Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Connect PawTrack Device",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Scan for and select your PawTrack ESP32 device.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // BLE Device Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedDevice,
                      hint: const Text("Select PawTrack Device"),
                      items: _bleDevices.map((device) {
                        return DropdownMenuItem(
                          value: device.remoteId.toString(),
                          child: Text(device.platformName.isNotEmpty
                              ? device.platformName
                              : "Unknown Device (${device.remoteId.toString().substring(0, 8)})"),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedDevice = value),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.bluetooth),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scan Button
                    CustomButton(
                      text: _isScanning ? "Scanning..." : "Scan for Devices",
                      icon: Icons.bluetooth_searching,
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: _isScanning ? null : _scanForDevices,
                    ),

                    if (_isScanning) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],

                    const SizedBox(height: 8),
                    Text(
                      "Make sure your PawTrack device is powered on and nearby.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Add Pet Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                text: "Add Pet & Setup GPS",
                icon: Icons.pets,
                onTap: _addPet,
              ),

              const SizedBox(height: 16),

              // Info text
              Text(
                "After adding your pet, you'll need to calibrate the GPS sensor for accurate location tracking.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}