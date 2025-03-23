import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pawtrack/auth/access_mode.dart';
import 'package:pawtrack/pages/home_page.dart';
import 'package:pawtrack/pages/welcome_page.dart';
import 'package:pawtrack/theme/theme.dart';
import 'package:pawtrack/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded successfully");
  } catch (e) {
    print("Error loading environment variables: $e");
    // Continue anyway, but Firebase init might fail
  }

  // Initialize Firebase with options from .env
  try {
    print("Initializing Firebase with:");
    print("API Key: ${dotenv.env['FIREBASE_API_KEY']?.substring(0, 3)}...");
    print("Project ID: ${dotenv.env['FIREBASE_PROJECT_ID']}");

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      ),
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Continue anyway, but auth will fail
  }

  // Request notification permission for Android 13+
  await _requestNotificationPermission();

  // Run the app inside ChangeNotifierProvider
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> _requestNotificationPermission() async {
  // Request notification permission for Android 13+
  if (await Permission.notification.isDenied) {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      print("Notification permission denied");
    } else if (status.isPermanentlyDenied) {
      print("Notification permission permanently denied. Please enable it in settings.");

      await openAppSettings();
    } else {
      print("Notification permission granted");
    }
  } else {
    print("Notification permission already granted");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PawTrack',
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routes: {
        AppRoutes.root: (context) => const AuthWrapper(),
        AppRoutes.welcome: (context) => const WelcomePage(),
        AppRoutes.access: (context) => const AccessMode(),
        AppRoutes.home: (context) => const HomePage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _hasSeenWelcome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('hasSeenWelcome') ?? false;
    } catch (e) {
      print("Error checking welcome preference: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print("Auth state changed: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, data: ${snapshot.data?.uid}");

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }

        return FutureBuilder<bool>(
          future: _hasSeenWelcome(),
          builder: (context, welcomeSnapshot) {
            if (welcomeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return welcomeSnapshot.data == true ? const AccessMode() : const WelcomePage();
          },
        );
      },
    );
  }
}