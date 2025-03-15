import 'package:flutter/material.dart';

class LocationTrackerPage extends StatelessWidget {
  const LocationTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location Tracker"),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2), // Added
      ),
      body: const Center(child: Text("Location Tracker Page - Coming Soon")),
    );
  }
}