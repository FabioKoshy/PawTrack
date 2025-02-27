import 'package:flutter/material.dart';
import 'package:pawtrack/auth/access_mode.dart';
import 'package:pawtrack/theme/dark_mode.dart';
import 'package:pawtrack/theme/light_mode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AccessMode(),
      theme: lightMode,
      darkTheme: darkMode,
    );
  }


}




