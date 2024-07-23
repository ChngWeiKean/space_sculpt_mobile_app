import 'package:flutter/material.dart';

class DropdownInput extends StatefulWidget {
  final String labelText;
  final List<String> items;
  final String? selectedItem;
  final Function(String?)? onChanged;
  final bool editable;

  const DropdownInput({
    super.key,
    required this.labelText,
    required this.items,
    this.selectedItem,
    this.onChanged,
    this.editable = true,
  });

  @override
  _DropdownInputState createState() => _DropdownInputState();
}

class _DropdownInputState extends State<DropdownInput> {
  String? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.selectedItem;
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
        DropdownButtonFormField<String>(
          value: _selectedItem,
          onChanged: widget.editable ? (value) {
            setState(() {
              _selectedItem = value;
            });
            widget.onChanged?.call(value);
          } : null,
          decoration: InputDecoration(
            hintText: 'Select an option',
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
          ),
          items: widget.items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}
