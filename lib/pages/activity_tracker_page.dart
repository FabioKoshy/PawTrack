import 'package:flutter/material.dart';

class ActivityTrackerPage extends StatelessWidget {
  final String petId;

  const ActivityTrackerPage({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Tracker'),
      ),
      body: Center(
        child: Text('COMING SOON!! Activity tracking for pet with ID: $petId'),
      ),
    );
  }
}