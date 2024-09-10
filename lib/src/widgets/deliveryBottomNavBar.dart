import 'package:flutter/material.dart';
import 'package:space_sculpt_mobile_app/colors.dart';
import 'package:space_sculpt_mobile_app/routes.dart';

class DeliveryBottomNavBar extends StatefulWidget {
  final int initialIndex;

  const DeliveryBottomNavBar({super.key, required this.initialIndex});

  @override
  _DeliveryBottomNavBarState createState() => _DeliveryBottomNavBarState();
}

class _DeliveryBottomNavBarState extends State<DeliveryBottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, Routes.dashboard);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, Routes.deliveryOrderHistory);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, Routes.deliveryDriverProfile);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, Routes.deliveryDriverSettings);
        break;
    }
  }

  List<BottomNavigationBarItem> _buildBottomNavigationBarItems() {
    return [
      BottomNavigationBarItem(
        icon: Icon(
          Icons.home_outlined,
          color: _selectedIndex == 0 ? AppColors.secondary : Colors.black54,
        ),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.receipt_long_outlined,
          color: _selectedIndex == 1 ? AppColors.secondary : Colors.black54,
        ),
        label: 'Orders',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.person_outline,
          color: _selectedIndex == 2 ? AppColors.secondary : Colors.black54,
        ),
        label: 'Profile',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.settings_outlined,
          color: _selectedIndex == 3 ? AppColors.secondary : Colors.black54,
        ),
        label: 'Settings',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedFontSize: 12.0,
      unselectedFontSize: 12.0,
      selectedLabelStyle: const TextStyle(color: AppColors.secondary),
      showUnselectedLabels: true,
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      items: _buildBottomNavigationBarItems(),
      onTap: _onItemTapped,
    );
  }
}
