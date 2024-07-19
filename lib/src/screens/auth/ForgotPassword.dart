import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/toast.dart';
import '../../../routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/input.dart';
import '../../widgets/button.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> _sendPasswordResetEmail(BuildContext context) async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      Toast.showErrorToast(title: 'Error',
          description: 'Email is required',
          context: context);
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(email);

      if (!context.mounted) return;

      Toast.showSuccessToast(title: 'Success',
          description: 'Password reset email sent.',
          context: context);

      Navigator.pushNamed(context, Routes.login);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Toast.showErrorToast(title: 'Error',
            description: 'No user found for that email.',
            context: context);
      } else {
        Toast.showErrorToast(title: 'Error',
            description: 'An unknown error occurred.',
            context: context);
      }
    } catch (e) {
      Toast.showErrorToast(title: 'Error',
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
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Reset Your Password',
                    style: TextStyle(
                      fontFamily: 'Poppins_Bold',
                      color: Colors.blue,
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
                const SizedBox(height: 40),
                Button(
                  text: 'Send Password Reset Email',
                  onPressed: () => _sendPasswordResetEmail(context),
                ),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      _navigateToLogin(context);
                    },
                    child: const Text(
                      'Back to Login',
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
