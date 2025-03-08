import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pawtrack/components/custom_button.dart';
import 'package:pawtrack/components/custom_text_field.dart';
import 'package:pawtrack/services/auth_service.dart';
import 'package:pawtrack/utils/constants.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;

  void register() async {
    if (!_formKey.currentState!.validate() || isLoading) return;
    setState(() => isLoading = true);
    try {
      await _authService.register(
        emailController.text.trim(),
        passwordController.text.trim(),
        usernameController.text.trim(),
      );
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final double topPadding = isKeyboardVisible ? 10.0 : 20.0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: topPadding),
                SvgPicture.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? 'assets/images/paw_heart_dark_logo.svg'
                      : 'assets/images/paw_heart_light_logo.svg',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: 10),
                Text('PawTrack', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                Column(
                  children: [
                    CustomTextField(
                      hintText: "Username",
                      obscureText: false,
                      controller: usernameController,
                      validator: (value) => value!.isEmpty ? 'Username is required' : null,
                    ),
                    const SizedBox(height: 10),
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
                      validator: (value) =>
                      value!.length < 6 ? 'Password must be 6+ characters' : null,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      hintText: "Confirm Password",
                      obscureText: true,
                      controller: confirmPasswordController,
                      validator: (value) =>
                      value != passwordController.text ? 'Passwords do not match' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(text: "Register", onTap: register),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}