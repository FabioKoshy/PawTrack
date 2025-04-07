import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String name;
  final String bluetoothDeviceId;
  final int? age;
  final String? breed;
  final double? weight;
  final String? imageUrl;
  final bool isGpsCalibrated;
  final DateTime? lastGpsCalibration;
  final String? espDeviceId;

  Pet({
    required this.id,
    required this.name,
    required this.bluetoothDeviceId,
    this.age,
    this.breed,
    this.weight,
    this.imageUrl,
    this.isGpsCalibrated = false,
    this.lastGpsCalibration,
    this.espDeviceId,
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
      isGpsCalibrated: data['isGpsCalibrated'] ?? false,
      lastGpsCalibration: data['lastGpsCalibration'] != null
          ? (data['lastGpsCalibration'] as Timestamp).toDate()
          : null,
      espDeviceId: data['espDeviceId'],
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
      'isGpsCalibrated': isGpsCalibrated,
      'lastGpsCalibration': lastGpsCalibration != null ? Timestamp.fromDate(lastGpsCalibration!) : null,
      'espDeviceId': espDeviceId,
    };
  }

  // Create a copy with updated fields
  Pet copyWith({
    String? name,
    String? bluetoothDeviceId,
    int? age,
    String? breed,
    double? weight,
    String? imageUrl,
    bool? isGpsCalibrated,
    DateTime? lastGpsCalibration,
    String? espDeviceId,
  }) {
    return Pet(
      id: this.id,
      name: name ?? this.name,
      bluetoothDeviceId: bluetoothDeviceId ?? this.bluetoothDeviceId,
      age: age ?? this.age,
      breed: breed ?? this.breed,
      weight: weight ?? this.weight,
      imageUrl: imageUrl ?? this.imageUrl,
      isGpsCalibrated: isGpsCalibrated ?? this.isGpsCalibrated,
      lastGpsCalibration: lastGpsCalibration ?? this.lastGpsCalibration,
      espDeviceId: espDeviceId ?? this.espDeviceId,
    );
  }
}