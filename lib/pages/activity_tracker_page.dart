import 'package:flutter/material.dart';

class ActivityTrackerPage extends StatelessWidget {
  const ActivityTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity Tracker"),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2), // Added
      ),
      body: const Center(child: Text("Activity Tracker Page - Coming Soon")),
    );
  }
}