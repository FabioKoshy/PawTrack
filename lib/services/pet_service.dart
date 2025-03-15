import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawtrack/models/pet.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Pet>> getPets() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .get();
    return snapshot.docs.map((doc) => Pet.fromFirestore(doc)).toList();
  }

  Future<void> addPet(String name, String bluetoothDeviceId) async {
    await _firestore.collection('users').doc(userId).collection('pets').add({
      'name': name,
      'bluetoothDeviceId': bluetoothDeviceId,
    });
  }

  Future<void> deletePet(String petId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .delete();
  }
}