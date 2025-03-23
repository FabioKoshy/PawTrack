import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawtrack/services/pet_service.dart';

class RecentLocationsPage extends StatefulWidget {
  final String petId;
  const RecentLocationsPage({super.key, required this.petId});

  @override
  State<RecentLocationsPage> createState() => _RecentLocationsPageState();
}

class _RecentLocationsPageState extends State<RecentLocationsPage> {
  final PetService _petService = PetService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent Locations"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_petService.userId)
            .collection('pets')
            .doc(widget.petId)
            .collection('locations')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No recent locations available."));
          }

          final locations = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index].data() as Map<String, dynamic>;
              final latitude = location['latitude']?.toDouble() ?? 0.0;
              final longitude = location['longitude']?.toDouble() ?? 0.0;
              final timestamp = location['timestamp']?.toString();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    "Location ${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Latitude: $latitude"),
                      Text("Longitude: $longitude"),
                      Text("Timestamp: ${_formatTimestamp(timestamp)}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }
}