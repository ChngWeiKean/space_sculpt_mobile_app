import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/toast.dart';
import '../../services/auth_service.dart';
import '../../widgets/input.dart';
import '../../widgets/button.dart';
import '../../../routes.dart';
import '../../../colors.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  String get logo => 'lib/src/assets/Space_Sculpt_Logo_nobg.png';

  Future<void> _register(BuildContext context) async {
    // Validate form fields
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _mobileNumberController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      Toast.showErrorToast(title: 'Error Signing Up',
          description: 'All fields are required.',
          context: context);
      return;
    }

    // Match passwords to confirm password
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      Toast.showErrorToast(title: 'Error Signing Up',
          description: 'Passwords do not match.',
          context: context);
      return;
    }

    try {
      final message = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        contact: _mobileNumberController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (message == 'Success') {
        if (!context.mounted) return;

        Toast.showSuccessToast(title: 'Success',
            description: 'Account created successfully.',
            context: context);

        // Fetch the registered user's data
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users/${user.uid}');
          DataSnapshot snapshot = await userRef.get();
          Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;

          if (!context.mounted) return;

          // Navigate based on user role
          if (userData['role'] == 'Customer') {
            Navigator.pushNamed(context, Routes.homepage);
          } else if (userData['role'] == 'Delivery') {
            Navigator.pushNamed(context, Routes.dashboard);
          }
        }
      } else {
        if (!context.mounted) return;

        Toast.showErrorToast(title: 'Error Signing Up',
            description: message!,
            context: context);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        if (!context.mounted) return;

        Toast.showErrorToast(title: 'Error Signing Up',
            description: 'The account already exists for that email.',
            context: context);
      } else {
        if (!context.mounted) return;

        Toast.showErrorToast(title: 'Error Signing Up',
            description: 'An unknown error occurred.',
            context: context);
      }
    } catch (e) {
      if (!context.mounted) return;

      Toast.showErrorToast(title: 'Error Signing Up',
          description: 'An unknown error occurred.',
          context: context);
    }
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushNamed(context, Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(logo, height: 80),
                    const SizedBox(width: 20),
                    const Text(
                      'Register',
                      style: TextStyle(
                        fontFamily: 'Poppins_Bold',
                        color: AppColors.primary,
                        fontSize: 40.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                Input(
                  controller: _nameController,
                  labelText: 'Name',
                  placeholder: 'John Doe',
                ),
                const SizedBox(height: 15),
                Input(
                  controller: _emailController,
                  labelText: 'Email',
                  placeholder: 'john.doe@gmail.com',
                ),
                const SizedBox(height: 15),
                Input(
                  controller: _mobileNumberController,
                  labelText: 'Mobile Number',
                  placeholder: '0124567890',
                ),
                const SizedBox(height: 15),
                Input(
                  controller: _passwordController,
                  labelText: 'Password',
                  placeholder: '********',
                  obscureText: true,
                ),
                const SizedBox(height: 15),
                Input(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  placeholder: '********',
                  obscureText: true,
                ),
                const SizedBox(height: 50),
                Button(
                  text: 'Register',
                  onPressed: () => _register(context),
                ),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      _navigateToLogin(context);
                    },
                    child: const Text(
                      'Already have an account? Log In',
                      style: TextStyle(
                        fontFamily: 'Poppins_Medium',
                        fontSize: 14.0,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
