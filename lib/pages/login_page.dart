import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/components/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;

  void login() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showErrorSnackBar('Please enter a valid email');
    } else if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logging in with $email')),
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
                  CustomTextField(
                    hintText: "Email",
                    obscureText: false,
                    controller: emailController,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    hintText: "Password",
                    obscureText: true,
                    controller: passwordController,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            onChanged: (value) {
                              setState(() => rememberMe = value!);
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                          Text(
                            "Remember Me",
                            style: Theme.of(context).textTheme.bodyMedium, // Use theme default (black in light, white in dark)
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          _showErrorSnackBar("Forgot Password feature coming soon!");
                        },
                        child: Text(
                          "Forgot Password?",
                          style: Theme.of(context).textTheme.bodyMedium, // Use theme default (black in light, white in dark)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              CustomButton(text: "Login", onTap: login),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium, // Use theme default (black in light, white in dark)
                  ),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      "Register Here!",
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