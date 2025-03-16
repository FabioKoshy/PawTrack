import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      testing commit mia
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2), // Added
      ),
      body: const Center(child: Text("Notifications Page - Coming Soon")),
    );
  }
}