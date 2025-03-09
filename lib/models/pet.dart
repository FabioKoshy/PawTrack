import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String name;
  final String bluetoothDeviceId;

  Pet({
    required this.id,
    required this.name,
    required this.bluetoothDeviceId,
  });

  factory Pet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      name: data['name'] ?? '',
      bluetoothDeviceId: data['bluetoothDeviceId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'bluetoothDeviceId': bluetoothDeviceId,
    };
  }
}