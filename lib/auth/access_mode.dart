import 'package:flutter/material.dart';
import 'package:pawtrack/pages/login_page.dart'; // Correct: login_page is in pages
import 'package:pawtrack/pages/register_page.dart'; // Correct: register_page is in pages

class AccessMode extends StatefulWidget {
  const AccessMode({super.key});

  @override
  State<AccessMode> createState() => _AccessModeState();
}

class _AccessModeState extends State<AccessMode> {
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(onTap: togglePages);
    } else {
      return RegisterPage(onTap: togglePages);
    }
  }
}