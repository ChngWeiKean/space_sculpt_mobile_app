import 'package:flutter/material.dart';
import '../../colors.dart';

class TitleBar extends StatelessWidget {
  final String title;
  final bool hasBackButton;

  const TitleBar({required this.title, this.hasBackButton = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0, bottom: 10.0, left: 20.0, right: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.secondary, size: 20.0),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins_Bold',
                  color: AppColors.secondary,
                  fontSize: 20.0,
                ),
              ),
            ),
          ),
          if (hasBackButton)
            const SizedBox(width: 48), // Space to keep the title centered when there's a back button
        ],
      ),
    );
  }
}
