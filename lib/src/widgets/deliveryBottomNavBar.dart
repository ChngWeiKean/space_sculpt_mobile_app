import 'package:flutter/material.dart';
import 'package:space_sculpt_mobile_app/colors.dart';
import 'package:space_sculpt_mobile_app/routes.dart';

class DeliveryBottomNavBar extends StatefulWidget {
  const DeliveryBottomNavBar({super.key});

  @override
  _DeliveryBottomNavBarState createState() => _DeliveryBottomNavBarState();
}

class _DeliveryBottomNavBarState extends State<DeliveryBottomNavBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, Routes.dashboard);
        break;
      case 1:
        Navigator.pushNamed(context, '/orders');
        break;
      case 2:
        Navigator.pushNamed(context, '/profile');
        break;
      case 3:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.secondary,
      selectedFontSize: 12.0,
      unselectedFontSize: 12.0,
      unselectedItemColor: Colors.black54,
      showUnselectedLabels: true,
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings'
        )
      ],
      onTap: _onItemTapped,
    );
  }
}
