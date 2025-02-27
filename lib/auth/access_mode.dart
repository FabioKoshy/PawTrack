import 'package:flutter/material.dart';
import 'package:pawtrack/pages/login_page.dart';
import 'package:pawtrack/pages/register_page.dart';

class AccessMode extends StatefulWidget {
  const AccessMode({super.key});

  @override
  State<AccessMode> createState() => _AccessModeState();
}

class _AccessModeState extends State<AccessMode> {

  // Initially ask to Log in
  bool showLoginPage = true;

  // Toggle between Login and Register page
  void togglePages(){
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if(showLoginPage){
      return LoginPage(onTap: togglePages);
    } else {
      return RegisterPage(onTap: togglePages);
    }
  }
}
