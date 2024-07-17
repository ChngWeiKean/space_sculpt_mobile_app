import 'package:flutter/material.dart';

class Input extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final String? placeholder; // Optional placeholder parameter

  const Input({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.placeholder, // Optional placeholder parameter
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontFamily: 'Poppins_Medium',
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: placeholder, // Set the placeholder text here
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.blueGrey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFF3182CE)),
            ),
            filled: true,
            fillColor: Colors.blueGrey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          ),
          style: const TextStyle(
            fontFamily: 'Poppins_Medium',
          ),
        ),
      ],
    );
  }
}
