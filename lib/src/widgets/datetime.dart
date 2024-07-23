import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeInput extends StatefulWidget {
  final String labelText;
  final DateTime? initialDate;
  final Function(DateTime)? onDateSelected;
  final bool editable;

  const DateTimeInput({
    super.key,
    required this.labelText,
    this.initialDate,
    this.onDateSelected,
    this.editable = true,
  });

  @override
  _DateTimeInputState createState() => _DateTimeInputState();
}

class _DateTimeInputState extends State<DateTimeInput> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!widget.editable) return;

    DateTime initialDate = _selectedDate ?? DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      widget.onDateSelected?.call(pickedDate);
    }
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
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: TextField(
              controller: TextEditingController(
                text: _selectedDate != null
                    ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                    : '',
              ),
              decoration: InputDecoration(
                hintText: 'Select a date',
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
              readOnly: true,
            ),
          ),
        ),
      ],
    );
  }
}
