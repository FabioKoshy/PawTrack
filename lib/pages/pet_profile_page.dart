import 'package:flutter/material.dart';
import 'package:pawtrack/models/pet.dart';

class PetProfilePage extends StatelessWidget {
  final Pet pet;

  const PetProfilePage({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${pet.name}'s Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 80), // Replace image with icon
            const SizedBox(height: 20),
            Text(pet.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                title: const Text("Bluetooth Device"),
                subtitle: Text(pet.bluetoothDeviceId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}