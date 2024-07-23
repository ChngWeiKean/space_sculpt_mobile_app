import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../widgets/customerBottomNavBar.dart';
import '../../widgets/input.dart';
import '../../widgets/title.dart';
import '../../../routes.dart';
import '../../../colors.dart';

class CustomerProfile extends StatefulWidget {
  const CustomerProfile({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<CustomerProfile> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _genderController = TextEditingController();
  User? _currentUser;
  Map<dynamic, dynamic>? _userData;
  late DatabaseReference _dbRef;

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
        _emailController.text = _userData?['email'] ?? '';
        _mobileNumberController.text = _userData?['contact'] ?? '';
        _birthdayController.text = _userData?['date_of_birth'] ?? '';
        _genderController.text = _userData?['gender'] ?? '';
      }
    }
  }

  void _editProfile() {
    // Navigate to edit profile page
    Navigator.pushNamed(context, Routes.customerEditProfile);
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
                const TitleBar(title: 'Profile'),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Stack(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundImage: _userData?['profile_picture'] != null && _userData!['profile_picture'] != ''
                                        ? NetworkImage(_userData!['profile_picture'])
                                        : null, // No icon will be shown if an image is provided
                                    radius: 50, // No image will be shown, so fallback to icon
                                    child: _userData?['profile_picture'] == null || _userData!['profile_picture'] == ''
                                        ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.secondary,
                                    )
                                        : null,
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 0,
                                right: 70,
                                child: IconButton(
                                  icon: const Icon(Icons.edit, color: AppColors.secondary),
                                  onPressed: _editProfile,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Input(
                            controller: _nameController,
                            labelText: 'Name',
                            placeholder: 'John Doe',
                            editable: false, // Make it non-editable
                          ),
                          const SizedBox(height: 15),
                          Input(
                            controller: _emailController,
                            labelText: 'Email',
                            placeholder: 'john.doe@gmail.com',
                            editable: false, // Make it non-editable
                          ),
                          const SizedBox(height: 15),
                          Input(
                            controller: _mobileNumberController,
                            labelText: 'Mobile Number',
                            placeholder: '0124567890',
                            editable: false, // Make it non-editable
                          ),
                          const SizedBox(height: 15),
                          Input(
                            controller: _birthdayController,
                            labelText: 'Date of Birth',
                            placeholder: '',
                            editable: false, // Make it non-editable
                          ),
                          const SizedBox(height: 15),
                          Input(
                            controller: _genderController,
                            labelText: 'Gender',
                            placeholder: '',
                            editable: false, // Make it non-editable
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
      bottomNavigationBar: const CustomerBottomNavBar(initialIndex: 3),
    );
  }
}
