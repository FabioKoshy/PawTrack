import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/components/custom_text_field.dart';
import 'package:pawtrack/services/auth_service.dart';
import 'package:pawtrack/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class LoginPage extends StatefulWidget {
  final VoidCallback? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  bool isLoading = false;
  late SharedPreferences prefs;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      prefs = await SharedPreferences.getInstance();
      rememberMe = prefs.getBool('rememberMe') ?? false;
      if (rememberMe) {
        emailController.text = prefs.getString('email') ?? '';
        passwordController.text = prefs.getString('password') ?? '';
      }
      if (mounted) setState(() {});
    } catch (e) {
      print("Error initializing preferences: $e");
      // Continue without loading preferences
    }
  }

  void _printDebugInfo() {
    print("=== DEBUG INFO ===");
    print("Email: ${emailController.text}");
    print("Password length: ${passwordController.text.length}");
    print("Remember me: $rememberMe");
  }

  Future<void> login() async {
    _printDebugInfo();

    // Clear previous error
    setState(() {
      errorMessage = null;
    });

    if (!_formKey.currentState!.validate() || isLoading) {
      print("Form validation failed or already loading");
      return;
    }

    setState(() => isLoading = true);
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    print("Attempting login with email: $email");

    try {
      print("Calling Firebase authentication...");
      User? user = await _authService.login(email, password);
      print("Login result: ${user != null ? 'Success' : 'Failed'}, User ID: ${user?.uid}");

      // Only save preferences if login was successful
      try {
        await prefs.setBool('rememberMe', rememberMe);
        if (rememberMe) {
          await prefs.setString('email', email);
          await prefs.setString('password', password);
          print("Credentials saved to SharedPreferences");
        } else {
          await prefs.remove('email');
          await prefs.remove('password');
          print("Credentials removed from SharedPreferences");
        }
      } catch (e) {
        print("Warning: Failed to save preferences: $e");
        // Continue anyway since login was successful
      }

      if (mounted) {
        print("Navigating to home page");
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: Code: ${e.code}, Message: ${e.message}");

      // Provide user-friendly error messages
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided for this user.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many login attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }

      setState(() {
        errorMessage = message;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } on TimeoutException catch (e) {
      print("Timeout error: $e");
      setState(() {
        errorMessage = "Login timed out. Please check your connection.";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Login timed out. Please check your connection."),
              backgroundColor: Colors.red
          ),
        );
      }
    } catch (e) {
      print("Unexpected error during login: $e");
      setState(() {
        errorMessage = "An unexpected error occurred. Please try again.";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An unexpected error occurred. Please try again.'),
              backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
      print("Login process completed");
    }
  }

  Future<void> _resetPassword() async {
    String email = emailController.text.trim();
    print("Attempting password reset for email: $email");

    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      print("Invalid email format for password reset");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      print("Calling Firebase resetPassword...");
      await _authService.resetPassword(email);
      print("Password reset email sent successfully");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during reset: Code: ${e.code}, Message: ${e.message}");

      // Provide user-friendly error messages
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = e.message ?? 'Failed to send reset email. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("Unexpected error during password reset: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An unexpected error occurred. Please try again.'),
              backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: AppPadding.pagePadding,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  SvgPicture.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/paw_heart_dark_logo.svg'
                        : 'assets/images/paw_heart_light_logo.svg',
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 20),
                  Text('PawTrack', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 40),
                  Column(
                    children: [
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      CustomTextField(
                        hintText: "Email",
                        obscureText: false,
                        controller: emailController,
                        validator: (value) =>
                        value!.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        hintText: "Password",
                        obscureText: true,
                        controller: passwordController,
                        validator: (value) => value!.isEmpty ? 'Password is required' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (value) => setState(() => rememberMe = value!),
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                              Text("Remember Me", style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          GestureDetector(
                            onTap: _resetPassword,
                            child: Text("Forgot Password?",
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : CustomButton(text: "Login", onTap: login),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium),
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}