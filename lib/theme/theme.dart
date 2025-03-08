import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Colors.white,
    primary: Colors.pink.shade300,
    secondary: Colors.grey.shade400,
    inversePrimary: Colors.grey.shade600,
    onPrimary: Colors.white,
  ),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: Colors.black,
    displayColor: Colors.black,
  ).copyWith(
    bodyMedium: const TextStyle(fontSize: 18),
    headlineSmall: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: Colors.black,
    primary: Colors.pink.shade300,
    secondary: Colors.grey.shade700,
    inversePrimary: Colors.grey.shade500,
    onPrimary: Colors.white,
  ),
  textTheme: ThemeData.dark().textTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ).copyWith(
    bodyMedium: const TextStyle(fontSize: 18),
    headlineSmall: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
  ),
);

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}