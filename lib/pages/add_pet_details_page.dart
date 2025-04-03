import 'package:flutter/material.dart';
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
  String? selectedDevice;
  final List<String> mockBluetoothDevices = ['Device1', 'Device2', 'Device3']; // Mock devices
  final PetService _petService = PetService();

  void _addPet() async {
    if (nameController.text.isEmpty || selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    await _petService.addPet(nameController.text, selectedDevice!);
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
            CustomButton(text: "Add Pet", onTap: _addPet),
          ],
        ),
      ),
    );
  }
}