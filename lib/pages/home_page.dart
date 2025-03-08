import 'package:flutter/material.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/services/auth_service.dart';
import 'package:pawtrack/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/access_mode.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);

    await AuthService().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AccessMode()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: AppPadding.pagePadding,
        child: Column(
          children: [
            Text(
              'Welcome, ${user.displayName ?? user.email}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Track Your Pet',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    const Text('Coming soon: Real-time pet location tracking!'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}