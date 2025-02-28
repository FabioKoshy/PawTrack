import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/components/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  void register() {
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showErrorSnackBar('Please enter a valid email');
    } else if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
    } else if (password != confirmPassword) {
      _showErrorSnackBar('Passwords do not match');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registering $username')),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SvgPicture.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/images/paw_heart_dark_logo.svg'
                    : 'assets/images/paw_heart_light_logo.svg',
                height: 120,
                width: 120,
              ),
              Text(
                'PawTrack',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Column(
                children: [
                  CustomTextField(hintText: "Username", obscureText: false, controller: usernameController),
                  const SizedBox(height: 10),
                  CustomTextField(hintText: "Email", obscureText: false, controller: emailController),
                  const SizedBox(height: 10),
                  CustomTextField(hintText: "Password", obscureText: true, controller: passwordController),
                  const SizedBox(height: 10),
                  CustomTextField(hintText: "Confirm Password", obscureText: true, controller: confirmPasswordController),
                ],
              ),
              CustomButton(text: "Register", onTap: register),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium, // Use theme default (black in light, white in dark)
                  ),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      "Login Here!",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}