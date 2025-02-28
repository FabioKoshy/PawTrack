import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Colors.white, // White background
    primary: Colors.pink.shade300, // Pink accents remain
    secondary: Colors.grey.shade400,
    inversePrimary: Colors.grey.shade600,
  ),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: Colors.black, // Black text for primary text
    displayColor: Colors.black, // Black text for display text
  ).copyWith(
    bodyMedium: const TextStyle(fontSize: 18), // Larger default text size
    headlineSmall: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), // For app title
  ),
);