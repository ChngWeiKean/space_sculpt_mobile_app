import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../widgets/toast.dart';
import '../../widgets/input.dart';
import '../../widgets/button.dart';
import '../../../routes.dart';
import '../../../colors.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/title.dart';

class DeliveryDriverEditProfile extends StatefulWidget {
  const DeliveryDriverEditProfile({super.key});

  @override
  _DeliveryDriverEditProfileState createState() => _DeliveryDriverEditProfileState();
}

class _DeliveryDriverEditProfileState extends State<DeliveryDriverEditProfile> {
  final _nameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  User? _currentUser;
  Map<dynamic, dynamic>? _userData;
  late DatabaseReference _dbRef;

  final UserProfileService _userProfileService = UserProfileService();

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
        _nameController.text = _userData?['name'] ?? '';
        _mobileNumberController.text = _userData?['contact'] ?? '';
      }
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    if (_currentUser != null) {
      try {
        // await _userProfileService.editCustomerProfile({
        //   'name': _nameController.text,
        //   'contact': _mobileNumberController.text,
        // });

        if (!context.mounted) return;

        Toast.showSuccessToast(
          title: 'Success',
          description: 'Successfully updated profile',
          context: context,
        );

        // Navigate back to the homepage or other appropriate page
        Navigator.pushReplacementNamed(context, Routes.homepage);
      } catch (e) {
        print('Error: $e');
        if (!context.mounted) return;

        Toast.showErrorToast(
          title: 'Error',
          description: 'An error occurred while updating profile',
          context: context,
        );
      }
    }
  }

  void _navigateToUpdateEmail() {
    Navigator.pushNamed(context, Routes.updateEmail);
  }

  void _navigateToUpdatePassword() {
    Navigator.pushNamed(context, Routes.updatePassword);
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
                const TitleBar(title: 'Edit Profile', hasBackButton: true),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Input(
                            controller: _nameController,
                            labelText: 'Name',
                            placeholder: 'John Doe',
                          ),
                          const SizedBox(height: 15),
                          Input(
                            controller: _mobileNumberController,
                            labelText: 'Mobile Number',
                            placeholder: '0124567890',
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _navigateToUpdateEmail,
                                child: const Text(
                                  'Update email',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontFamily: 'Poppins_Medium',
                                    fontSize: 14.0,
                                  ),
                                ),
                              ),
                              const Text(' or ', style: TextStyle(fontSize: 14.0, fontFamily: 'Poppins_Medium')),
                              TextButton(
                                onPressed: _navigateToUpdatePassword,
                                child: const Text(
                                  'password here',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontFamily: 'Poppins_Medium',
                                    fontSize: 14.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Button(
                            text: 'Save Changes',
                            onPressed: () => _editProfile(context),
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
    );
  }
}
