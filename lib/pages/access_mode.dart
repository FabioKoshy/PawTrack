import 'package:flutter/material.dart';
import 'package:pawtrack/pages/login_page.dart';
import 'package:pawtrack/pages/register_page.dart';

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
    return showLoginPage ? LoginPage(onTap: togglePages) : RegisterPage(onTap: togglePages);
  }
}