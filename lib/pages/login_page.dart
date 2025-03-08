import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/components/custom_text_field.dart';
import 'package:pawtrack/services/auth_service.dart';
import 'package:pawtrack/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;

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

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    rememberMe = prefs.getBool('rememberMe') ?? false;
    if (rememberMe) {
      emailController.text = prefs.getString('email') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
    }
    if (mounted) setState(() {});
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate() || isLoading) return;
    setState(() => isLoading = true);
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    print('Attempting login with email: $email');
    try {
      await _authService.login(email, password);
      print('Login successful');
      await prefs.setBool('rememberMe', rememberMe);
      if (rememberMe) {
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      } else {
        await prefs.remove('email');
        await prefs.remove('password');
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        print('Navigating to HomePage');
      }
    } on FirebaseAuthException catch (e) {
      print('Login failed: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    String email = emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email'), backgroundColor: Colors.red),
      );
      return;
    }
    try {
      await _authService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Failed to send reset email'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView( // Add scrollable content
        child: SafeArea(
          child: Padding(
            padding: AppPadding.pagePadding,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20), // Top padding
                  SvgPicture.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/paw_heart_dark_logo.svg'
                        : 'assets/images/paw_heart_light_logo.svg',
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PawTrack',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 40),
                  Column(
                    children: [
                      CustomTextField(
                        hintText: "Email",
                        obscureText: false,
                        controller: emailController,
                        validator: (value) => value!.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)
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
                                onChanged: (value) {
                                  setState(() => rememberMe = value!);
                                },
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                              Text(
                                "Remember Me",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _resetPassword,
                            child: Text(
                              "Forgot Password?",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : CustomButton(text: "Login", onTap: login),
                  const SizedBox(height: 8), // Reduced spacing to match register page
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
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