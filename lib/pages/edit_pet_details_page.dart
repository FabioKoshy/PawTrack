import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/components/custom_text_field.dart';
import 'package:pawtrack/models/pet.dart';
import 'package:pawtrack/services/pet_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bluetooth_pairing_page.dart';

class EditPetDetailsPage extends StatefulWidget {
  final Pet pet;
  const EditPetDetailsPage({super.key, required this.pet});

  @override
  State<EditPetDetailsPage> createState() => _EditPetDetailsPageState();
}

class _EditPetDetailsPageState extends State<EditPetDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  File? _image;
  String? _existingImageUrl;
  final PetService _petService = PetService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? wifiConnectionStatus;
  String? wifiNetwork; // Store the Wi-Fi SSID locally

  @override
  void initState() {
    super.initState();
    nameController.text = widget.pet.name;
    ageController.text = widget.pet.age?.toString() ?? '';
    breedController.text = widget.pet.breed ?? '';
    weightController.text = widget.pet.weight?.toString() ?? '';
    _existingImageUrl = widget.pet.imageUrl;
    wifiConnectionStatus = 'Connected'; // Assume connected for existing pet
    wifiNetwork = widget.pet.wifiNetwork; // Load existing wifiNetwork
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
        setState(() => _image = File(pickedFile.path));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo permission required'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Please enable photo access in settings.'),
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

  void _updatePet() async {
    if (nameController.text.isEmpty || wifiConnectionStatus != 'Connected') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields (Name and Wi-Fi Configuration)')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      String? imageUrl = _existingImageUrl;
      if (_image != null) {
        imageUrl = await _petService.uploadPetImage(_image!, widget.pet.id);
      }
      int? age = ageController.text.isNotEmpty ? int.tryParse(ageController.text) : null;
      if (age == null && ageController.text.isNotEmpty) {
        throw 'Age must be a valid number';
      }
      double? weight = weightController.text.isNotEmpty ? double.tryParse(weightController.text) : null;
      if (weight == null && weightController.text.isNotEmpty) {
        throw 'Weight must be a valid number';
      }
      await _petService.updatePet(
        widget.pet.id,
        name: nameController.text,
        bluetoothDeviceId: 'ESP32_PetTracker',
        age: age,
        breed: breedController.text.isNotEmpty ? breedController.text : null,
        weight: weight,
        imageUrl: imageUrl,
        wifiNetwork: wifiNetwork, // Pass the updated SSID
      );
      final updatedPet = Pet(
        id: widget.pet.id,
        name: nameController.text,
        bluetoothDeviceId: 'ESP32_PetTracker',
        age: age,
        breed: breedController.text.isNotEmpty ? breedController.text : null,
        weight: weight,
        imageUrl: imageUrl,
        wifiNetwork: wifiNetwork,
      );
      Navigator.pop(context, updatedPet);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update pet: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Pet Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: _image != null
                      ? ClipOval(child: Image.file(_image!, fit: BoxFit.cover, width: 100, height: 100))
                      : _existingImageUrl != null
                      ? ClipOval(
                    child: Image.network(
                      _existingImageUrl!,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                    ),
                  )
                      : const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Pet Name",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Enter pet name",
                controller: nameController,
                obscureText: false,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              Text(
                "Age (Optional)",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Enter age",
                controller: ageController,
                obscureText: false,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Text(
                "Breed (Optional)",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              CustomTextField(hintText: "Enter breed", controller: breedController, obscureText: false),
              const SizedBox(height: 20),
              Text(
                "Weight in kg (Optional)",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Enter weight",
                controller: weightController,
                obscureText: false,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Text(
                "Wi-Fi Configuration for Device",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BluetoothPairingPage()),
                  );
                  if (result != null) {
                    setState(() {
                      wifiConnectionStatus = result['status'] == 'Connected' ? 'Connected' : 'Failed';
                      wifiNetwork = result['status'] == 'Connected' ? result['ssid'] : wifiNetwork;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Wi-Fi Status: $wifiConnectionStatus')),
                    );
                  }
                },
                child: const Text("Update Wi-Fi Connection"),
              ),
              const SizedBox(height: 20),
              _isLoading ? const CircularProgressIndicator() : CustomButton(text: "Update Pet", onTap: _updatePet),
            ],
          ),
        ),
      ),
    );
  }
}