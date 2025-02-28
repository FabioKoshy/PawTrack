import 'package:flutter/material.dart';
import 'package:pawtrack/pages/welcome_page.dart';
import 'package:pawtrack/theme/dark_mode.dart';
import 'package:pawtrack/theme/light_mode.dart';
import 'package:pawtrack/theme/theme_provider.dart'; // New import
import 'package:provider/provider.dart';

void main() {
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomePage(),
      theme: Provider.of<ThemeProvider>(context).isDarkMode ? darkMode : lightMode,
    );
  }
}