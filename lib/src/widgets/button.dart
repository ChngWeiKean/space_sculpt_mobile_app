import 'package:flutter/material.dart';
import '../../colors.dart';

class Button extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width; // Optional width parameter
  Color? color; // Optional color parameter

  Button({
    super.key,
    required this.text,
    required this.onPressed,
    this.width, // Optional width parameter
    this.color = AppColors.secondary, // Optional color parameter
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity, // Set the width to full width if width is not provided
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          backgroundColor: color, // Background color
          foregroundColor: Colors.white, // Text color
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins_Bold',
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}
