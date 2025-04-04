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
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:firebase_database/firebase_database.dart';
import 'package:pawtrack/pages/notifications_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Environment variables loaded successfully");
  } catch (e) {
    debugPrint("Error loading environment variables: $e");
  }

  // Initialize Firebase with options from .env
  try {
    debugPrint("Initializing Firebase with:");
    debugPrint("API Key: ${dotenv.env['FIREBASE_API_KEY']?.substring(0, 3)}...");
    debugPrint("Project ID: ${dotenv.env['FIREBASE_PROJECT_ID']}");

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      ),
    );
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Error initializing Firebase: $e");
  }

  // Initialize Supabase
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (supabaseUrl == null || supabaseUrl.isEmpty || supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase URL or Anon Key is missing in .env');
    }
    await supabase.Supabase.initialize( // Use alias
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    debugPrint("Supabase initialized successfully");
  } catch (e) {
    debugPrint("Error initializing Supabase: $e");
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

  // Initialize default tracking status
  FirebaseDatabase.instance.ref().child("sensor/tracking").set(false);
}

Future<void> _requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      debugPrint("Notification permission denied");
    } else if (status.isPermanentlyDenied) {
      debugPrint("Notification permission permanently denied. Please enable it in settings.");
      await openAppSettings();
    } else {
      debugPrint("Notification permission granted");
    }
  } else {
    debugPrint("Notification permission already granted");
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
        '/notifications': (context) => const NotificationsPage(),
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
      debugPrint("Error checking welcome preference: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint("Auth state changed: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, data: ${snapshot.data?.uid}");

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