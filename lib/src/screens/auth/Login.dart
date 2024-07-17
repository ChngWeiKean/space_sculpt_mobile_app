import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/colors.dart';
import 'package:toastification/toastification.dart';
import '../../../routes.dart';
import '../../widgets/input.dart';
import '../../widgets/button.dart';
import '../../services/auth_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String get logo => 'lib/src/assets/Space_Sculpt_Logo_nobg.png';

  Future<void> _login(BuildContext context) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Validate email and password
    if (email.isEmpty || password.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        icon: const Icon(Icons.error),
        title: const Text('Error Logging In'),
        description: const Text('Email and password are required.'),
        showProgressBar: true,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    final message = await _authService.login(email: email, password: password);

    if (message!.contains('Success')) {
      // Fetch user data from the database
      User? user = FirebaseAuth.instance.currentUser;
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
        } else {
          // Handle other roles or show an error
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.minimal,
            icon: const Icon(Icons.error),
            title: const Text('Error'),
            description: const Text('Unknown user role.'),
            showProgressBar: true,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      }
    } else {
      if (!context.mounted) return;
      // Display error message to the user
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        icon: const Icon(Icons.error),
        title: const Text('Error Logging In'),
        description: const Text('Invalid email or password.'),
        showProgressBar: true,
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.pushNamed(context, Routes.register);
  }

  void _navigateToForgotPassword(BuildContext context) {
    Navigator.pushNamed(context, Routes.forgotPassword);
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
                Image.asset(logo, height: 300),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Welcome To Space Sculpt',
                    style: TextStyle(
                      fontFamily: 'Poppins_Bold',
                      color: AppColors.primary,
                      fontSize: 24.0,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                Input(
                  controller: _emailController,
                  labelText: 'Email',
                  placeholder: 'john.doe@gmail.com',
                ),
                const SizedBox(height: 15),
                Input(
                  controller: _passwordController,
                  labelText: 'Password',
                  placeholder: '********',
                  obscureText: true,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _navigateToForgotPassword(context);
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontFamily: 'Poppins_Medium',
                        fontSize: 14.0,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                Button(
                  text: 'Log In',
                  onPressed: () => _login(context),
                ),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      _navigateToRegister(context);
                    },
                    child: const Text(
                      'Don\'t have an account? Sign Up Here',
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
