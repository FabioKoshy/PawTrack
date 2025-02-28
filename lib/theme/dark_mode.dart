import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: Colors.black, // Black background
    primary: Colors.pink.shade300, // Pink accents remain
    secondary: Colors.grey.shade700,
    inversePrimary: Colors.grey.shade500,
  ),
  textTheme: ThemeData.dark().textTheme.apply(
    bodyColor: Colors.white, // White text for primary text
    displayColor: Colors.white, // White text for display text
  ).copyWith(
    bodyMedium: const TextStyle(fontSize: 18), // Larger default text size
    headlineSmall: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), // For app title
  ),
);