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
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Container for My Addresses and My Vouchers
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.location_on),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  title: const Text(
                                            'Addresses',
                                            style: TextStyle(
                                              fontFamily: 'Poppins_Medium'
                                            ),
                                          ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                                  onTap: () {
                                    Navigator.pushNamed(context, Routes.customerAddresses);
                                  },
                                ),
                                const Divider(height: 1, thickness: 1),
                                ListTile(
                                  leading: const Icon(Icons.card_giftcard),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  title: const Text(
                                            'Vouchers',
                                            style: TextStyle(
                                                fontFamily: 'Poppins_Medium'
                                            ),
                                          ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                                  onTap: () {
                                    Navigator.pushNamed(context, Routes.customerVouchers);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Logout Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Button(
                              text: 'Logout',
                              onPressed: () => _logout(context),
                            ),
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
