import 'package:flutter/material.dart';
import '../../colors.dart';

class Input extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final String? placeholder;
  final bool editable;

  const Input({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.placeholder,
    this.editable = true,
  });

  @override
  _InputState createState() => _InputState();
}

class _InputState extends State<Input> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: const TextStyle(
            fontFamily: 'Poppins_Medium',
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: widget.controller,
          enabled: widget.editable,
          obscureText: _isObscured,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.blueGrey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFF3182CE)),
            ),
            filled: true,
            fillColor: Colors.blueGrey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            suffixIcon: widget.obscureText
                ? IconButton(
              icon: Icon(
                _isObscured ? Icons.visibility : Icons.visibility_off,
                color: AppColors.secondary,
              ),
              onPressed: () {
                setState(() {
                  _isObscured = !_isObscured;
                });
              },
            )
                : null,
          ),
          style: const TextStyle(
            fontFamily: 'Poppins_Medium',
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
