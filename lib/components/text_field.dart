import 'package:flutter/material.dart';

class TextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;

  const TextField({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller, required InputDecoration decoration,

  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      hintText: hintText,
      obscureText: obscureText,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
      ),
    );
  }
}
