import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:space_sculpt_mobile_app/src/widgets/toast.dart';
import 'dart:io';
import '../../widgets/input.dart';
import '../../widgets/button.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/datetime.dart';
import '../../../routes.dart';
import '../../../colors.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/title.dart';

class CustomerEditProfile extends StatefulWidget {
  const CustomerEditProfile({super.key});

  @override
  _CustomerEditProfileState createState() => _CustomerEditProfileState();
}

class _CustomerEditProfileState extends State<CustomerEditProfile> {
  final _nameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _genderController = TextEditingController();
  User? _currentUser;
  Map<dynamic, dynamic>? _userData;
  late DatabaseReference _dbRef;
  File? _profilePictureFile; // To store the selected profile picture

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
        _birthdayController.text = _userData?['date_of_birth'] ?? '';
        _genderController.text = _userData?['gender'] ?? '';
      }
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    if (_currentUser != null) {
      try {
        await _userProfileService.editCustomerProfile({
          'name': _nameController.text,
          'contact': _mobileNumberController.text,
          'date_of_birth': _birthdayController.text,
          'gender': _genderController.text,
        }, _profilePictureFile);

        if (!context.mounted) return;

        Toast.showSuccessToast(title: 'Success',
            description: 'Successfully updated profile',
            context: context);

        // Navigate back to the homepage or other appropriate page
        Navigator.pushReplacementNamed(context, Routes.homepage);
      } catch (e) {
        print('Error: $e');
        if (!context.mounted) return;

        Toast.showErrorToast(title: 'Error',
            description: 'An error occurred while updating profile',
            context: context);
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profilePictureFile = File(pickedFile.path);
      });
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
                          Stack(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundImage: _profilePictureFile != null
                                        ? FileImage(_profilePictureFile!) // Use local image if available
                                        : _userData?['profile_picture'] != null && _userData!['profile_picture'] != ''
                                        ? NetworkImage(_userData!['profile_picture']) // Fallback to network image
                                        : null, // Show icon only if no image available
                                    radius: 50, // If no image available, use null
                                    child: _profilePictureFile == null &&
                                        (_userData?['profile_picture'] == null || _userData!['profile_picture'] == '')
                                        ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey, // Customize icon color as needed
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
                                  onPressed: _pickImage, // Use _pickImage to handle image selection
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
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
                          const SizedBox(height: 15),
                          DateTimeInput(
                            labelText: 'Date of Birth',
                            initialDate: _userData?['date_of_birth'] != null
                                ? DateTime.tryParse(_userData!['date_of_birth'])
                                : null,
                            onDateSelected: (date) {
                              _birthdayController.text = DateFormat('yyyy-MM-dd').format(date);
                            },
                          ),
                          const SizedBox(height: 15),
                          DropdownInput(
                            labelText: 'Gender',
                            items: const ['Male', 'Female', 'Other'],
                            selectedItem: _genderController.text.isEmpty ? null : _genderController.text,
                            onChanged: (value) {
                              _genderController.text = value ?? '';
                            },
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
                              const Text(' or ', style: TextStyle(fontSize: 14.0, fontFamily: 'Poppins_Medium',),),
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
                            onPressed: () => _editProfile(context), // Use _editProfile to save changes
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
