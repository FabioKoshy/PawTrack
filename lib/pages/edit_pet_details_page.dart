import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/components/custom_text_field.dart';
import 'package:pawtrack/models/pet.dart';
import 'package:pawtrack/services/pet_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
  String? selectedDevice;
  File? _image;
  String? _existingImageUrl;
  final List<String> mockBluetoothDevices = ['Device1', 'Device2', 'Device3'];
  final PetService _petService = PetService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.pet.name;
    ageController.text = widget.pet.age?.toString() ?? '';
    breedController.text = widget.pet.breed ?? '';
    weightController.text = widget.pet.weight?.toString() ?? '';
    selectedDevice = widget.pet.bluetoothDeviceId;
    _existingImageUrl = widget.pet.imageUrl;
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

  void _updatePet() async {
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
      String? imageUrl = _existingImageUrl;
      if (_image != null) {
        print('Selected image path: ${_image!.path}');
        imageUrl = await _petService.uploadPetImage(_image!, widget.pet.id);
        print('New image URL: $imageUrl');
      }

      int? age;
      if (ageController.text.isNotEmpty) {
        age = int.tryParse(ageController.text);
        if (age == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Age must be a valid number'), backgroundColor: Colors.red),
          );
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
          return;
        }
      }

      await _petService.updatePet(
        widget.pet.id,
        name: nameController.text,
        bluetoothDeviceId: selectedDevice!,
        age: age,
        breed: breedController.text.isNotEmpty ? breedController.text : null,
        weight: weight,
        imageUrl: imageUrl,
      );

      final updatedPet = Pet(
        id: widget.pet.id,
        name: nameController.text,
        bluetoothDeviceId: selectedDevice!,
        age: age,
        breed: breedController.text.isNotEmpty ? breedController.text : null,
        weight: weight,
        imageUrl: imageUrl,
      );

      Navigator.pop(context, updatedPet);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update pet: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                      ? ClipOval(
                    child: Image.file(
                      _image!,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    ),
                  )
                      : _existingImageUrl != null
                      ? ClipOval(
                    child: Image.network(
                      _existingImageUrl!,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  )
                      : const Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              Text(
                "Bluetooth Device",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedDevice,
                hint: const Text("Select Bluetooth Device"),
                items: mockBluetoothDevices
                    .map((device) => DropdownMenuItem(value: device, child: Text(device)))
                    .toList(),
                onChanged: (value) => setState(() => selectedDevice = value),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : CustomButton(text: "Update Pet", onTap: _updatePet),
            ],
          ),
        ),
      ),
    );
  }
}