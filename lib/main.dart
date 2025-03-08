import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pawtrack/auth/access_mode.dart';
import 'package:pawtrack/pages/home_page.dart';
import 'package:pawtrack/pages/welcome_page.dart';
import 'package:pawtrack/theme/dark_mode.dart';
import 'package:pawtrack/theme/light_mode.dart';
import 'package:pawtrack/theme/theme_provider.dart';
import 'package:pawtrack/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Provider.of<ThemeProvider>(context).isDarkMode ? darkMode : lightMode,
        initialRoute: AppRoutes.root,
        routes: {
          AppRoutes.root: (context) => const AuthWrapper(),
          AppRoutes.welcome: (context) => const WelcomePage(),
          AppRoutes.access: (context) => const AccessMode(),
          AppRoutes.home: (context) => const HomePage(),
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US')],
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _hasSeenWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenWelcome') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        // If user is not logged in, check if they've seen the WelcomePage
        return FutureBuilder<bool>(
          future: _hasSeenWelcome(),
          builder: (context, welcomeSnapshot) {
            if (welcomeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // If they've seen the WelcomePage, go to AccessMode
            if (welcomeSnapshot.data == true) {
              return const AccessMode();
            }

            // If this is the first launch, show WelcomePage
            return const WelcomePage();
          },
        );
      },
    );
  }
}

class ErrorBoundary extends StatelessWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            body: Center(
              child: Text('An error occurred: ${details.exception}'),
            ),
          );
        };
        return child;
      },
    );
  }
}