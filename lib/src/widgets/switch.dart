import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

class TrueFalseSwitch extends StatelessWidget {
  final bool isOn;
  final Function(bool) onChanged;

  const TrueFalseSwitch({
    required this.isOn,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleSwitch(
      minWidth: 90.0,
      cornerRadius: 20.0,
      activeBgColors: [[Colors.green[800]!], [Colors.red[800]!]],
      activeFgColor: Colors.white,
      inactiveBgColor: Colors.grey,
      inactiveFgColor: Colors.white,
      initialLabelIndex: isOn ? 0 : 1,
      totalSwitches: 2,
      labels: const ['True', 'False'],
      radiusStyle: true,
      onToggle: (index) {
        onChanged(index == 0);
      },
    );
  }
}
