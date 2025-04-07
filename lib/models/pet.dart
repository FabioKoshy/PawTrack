import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String name;
  final String bluetoothDeviceId;
  final int? age;
  final String? breed;
  final double? weight;
  final String? imageUrl;
  final String? wifiNetwork; // Field for Wi-Fi network name (SSID)

  Pet({
    required this.id,
    required this.name,
    required this.bluetoothDeviceId,
    this.age,
    this.breed,
    this.weight,
    this.imageUrl,
    this.wifiNetwork,
  });

  factory Pet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      name: data['name'] ?? '',
      bluetoothDeviceId: data['bluetoothDeviceId'] ?? '',
      age: data['age'],
      breed: data['breed'],
      weight: data['weight']?.toDouble(),
      imageUrl: data['imageUrl'],
      wifiNetwork: data['wifiNetwork'], // Load from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'bluetoothDeviceId': bluetoothDeviceId,
      'age': age,
      'breed': breed,
      'weight': weight,
      'imageUrl': imageUrl,
      'wifiNetwork': wifiNetwork, // Save to Firestore
    };
  }
}