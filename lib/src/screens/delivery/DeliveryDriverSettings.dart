import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/src/widgets/deliveryBottomNavBar.dart';
import '../../services/auth_service.dart';
import '../../widgets/button.dart';
import '../../widgets/title.dart';
import '../../widgets/toast.dart';
import '../../../routes.dart';

class DeliveryDriverSettings extends StatefulWidget {
  const DeliveryDriverSettings({super.key});

  @override
  _DeliveryDriverSettingsState createState() => _DeliveryDriverSettingsState();
}

class _DeliveryDriverSettingsState extends State<DeliveryDriverSettings> {
  User? _currentUser;
  late DatabaseReference _dbRef;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _dbRef.onDisconnect();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();

    if (!context.mounted) return;
    // Navigate to login page
    Navigator.pushNamed(context, Routes.login);

    Toast.showSuccessToast(
      title: 'Success',
      description: 'Logged out successfully.',
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const TitleBar(title: 'Settings'),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Button(
                  text: 'Logout',
                  onPressed: () => _logout(context),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const DeliveryBottomNavBar(initialIndex: 3),
    );
  }
}
