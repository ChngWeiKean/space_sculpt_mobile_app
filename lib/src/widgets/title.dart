import 'package:flutter/material.dart';

class TitleBar extends StatelessWidget {
  final String title;
  final bool hasBackButton;

  const TitleBar({required this.title, this.hasBackButton = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0, left: 20.0, right: 20, bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.blueGrey, size: 25.0),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          if (hasBackButton) const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins_Bold',
              color: Colors.blueGrey,
              fontSize: 30.0,
            ),
          ),
          if (hasBackButton) const Spacer(flex: 2),
        ],
      ),
    );
  }
}
