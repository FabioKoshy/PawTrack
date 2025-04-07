import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:pawtrack/models/pet.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  String? get userId => _auth.currentUser?.uid;

  /// Fetches the list of pets for the current user from Firestore.
  Future<List<Pet>> getPets() async {
    if (userId == null) throw Exception('User not logged in');
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .get();
    return snapshot.docs.map((doc) => Pet.fromFirestore(doc)).toList();
  }

  /// Uploads a pet image to Supabase Storage and returns the public URL.
  Future<String> uploadPetImage(File image, String petId) async {
    if (userId == null) throw Exception('User not logged in');
    try {
      print('Uploading image for petId: $petId, path: ${image.path}');
      final fileName = 'users/$userId/pets/$petId/profile.jpg';
      // Delete existing image in Supabase Storage if it exists
      try {
        await _supabase.storage.from('pet-images').remove([fileName]);
        print('Deleted old image for petId: $petId');
      } catch (e) {
        print('No old image to delete or error: $e');
      }
      // Upload new image to Supabase Storage
      final response = await _supabase.storage.from('pet-images').upload(
        fileName,
        image,
        fileOptions: const supabase.FileOptions(upsert: true),
      );
      print('Image uploaded: $response');
      // Get public URL from Supabase Storage
      final url = _supabase.storage.from('pet-images').getPublicUrl(fileName);
      print('Public URL: $url');
      if (url.isEmpty) {
        throw Exception('Failed to get public URL for image');
      }
      return url;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Adds a new pet to Firestore and uploads the image to Supabase Storage if provided.
  Future<Pet> addPet(
      String name,
      String bluetoothDeviceId, {
        int? age,
        String? breed,
        double? weight,
        File? image,
      }) async {
    if (userId == null) throw Exception('User not logged in');
    try {
      // Create pet object without image URL initially
      final pet = Pet(
        id: '',
        name: name,
        bluetoothDeviceId: bluetoothDeviceId,
        age: age,
        breed: breed,
        weight: weight,
        imageUrl: null,
        isGpsCalibrated: false,
      );
      // Add pet metadata to Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .add(pet.toFirestore());

      // If an image is provided, upload it to Supabase and update Firestore with the URL
      String? imageUrl;
      if (image != null) {
        imageUrl = await uploadPetImage(image, docRef.id);
        await docRef.update({'imageUrl': imageUrl});
      }

      // Return the created pet with the ID
      return Pet(
        id: docRef.id,
        name: name,
        bluetoothDeviceId: bluetoothDeviceId,
        age: age,
        breed: breed,
        weight: weight,
        imageUrl: imageUrl,
        isGpsCalibrated: false,
      );
    } catch (e) {
      throw Exception('Failed to add pet: $e');
    }
  }

  /// Updates an existing pet in Firestore.
  Future<void> updatePet(
      String petId, {
        String? name,
        String? bluetoothDeviceId,
        int? age,
        String? breed,
        double? weight,
        String? imageUrl,
        bool? isGpsCalibrated,
        DateTime? lastGpsCalibration,
        String? espDeviceId,
      }) async {
    if (userId == null) throw Exception('User not logged in');
    final petRef =
    _firestore.collection('users').doc(userId).collection('pets').doc(petId);
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (bluetoothDeviceId != null) updates['bluetoothDeviceId'] = bluetoothDeviceId;
    if (age != null) updates['age'] = age;
    if (breed != null) updates['breed'] = breed;
    if (weight != null) updates['weight'] = weight;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (isGpsCalibrated != null) updates['isGpsCalibrated'] = isGpsCalibrated;
    if (lastGpsCalibration != null) updates['lastGpsCalibration'] = Timestamp.fromDate(lastGpsCalibration);
    if (espDeviceId != null) updates['espDeviceId'] = espDeviceId;
    await petRef.update(updates);
  }

  /// Deletes a pet from Firestore and its image from Supabase Storage.
  Future<void> deletePet(String petId) async {
    if (userId == null) throw Exception('User not logged in');
    // Delete pet metadata from Firestore
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .delete();
    // Delete pet image from Supabase Storage
    try {
      await _supabase.storage.from('pet-images').remove(['users/$userId/pets/$petId/profile.jpg']);
      print('Deleted image for petId: $petId');
    } catch (e) {
      print('Error deleting pet image: $e');
    }
  }
}