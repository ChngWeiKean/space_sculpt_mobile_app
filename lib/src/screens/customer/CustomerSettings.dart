import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/auth_service.dart';
import '../../widgets/customerBottomNavBar.dart';
import '../../widgets/button.dart';
import '../../widgets/title.dart';
import '../../widgets/toast.dart';
import '../../../routes.dart';
import '../../../colors.dart';

class CustomerSettings extends StatefulWidget {
  const CustomerSettings({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<CustomerSettings> {
  User? _currentUser;
  Map<dynamic, dynamic>? _userData;
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

  Future<void> _fetchData() async {
    await _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      final snapshot = await _dbRef.child('users/${_currentUser!.uid}').get();
      if (snapshot.exists) {
        _userData = snapshot.value as Map<dynamic, dynamic>;
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();

    if (!context.mounted) return;
    // Navigate to login page
    Navigator.pushNamed(context, Routes.login);

    Toast.showSuccessToast(title: 'Success', description: 'Logged out successfully.', context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const TitleBar(title: 'Settings'),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Button(
                            text: 'Logout',
                            onPressed: () => _logout(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: const CustomerBottomNavBar(initialIndex: 4),
    );
  }
}
