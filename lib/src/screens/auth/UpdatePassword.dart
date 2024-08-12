import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:space_sculpt_mobile_app/src/widgets/title.dart';
import '../../../colors.dart';
import '../../widgets/toast.dart';
import '../../services/auth_service.dart';
import '../../widgets/input.dart';
import '../../widgets/button.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({super.key});

  @override
  _UpdatePasswordState createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> _updatePassword(BuildContext context) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String newPassword = _newPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || newPassword.isEmpty) {
      Toast.showErrorToast(
        title: 'Error',
        description: 'All fields are required.',
        context: context,
      );
      return;
    }

    if (password == newPassword) {
      Toast.showErrorToast(
        title: 'Error',
        description: 'New password cannot be the same as the current password.',
        context: context,
      );
      return;
    }

    try {
      await _authService.updatePassword(newPassword);

      if (!context.mounted) return;

      Toast.showSuccessToast(
        title: 'Success',
        description: 'Password updated successfully.',
        context: context,
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        Toast.showErrorToast(
          title: 'Error',
          description: 'Please re-login to update your password.',
          context: context,
        );
      } else {
        Toast.showErrorToast(
          title: 'Error',
          description: 'An unknown error occurred.',
          context: context,
        );
      }
    } catch (e) {
      Toast.showErrorToast(
        title: 'Error',
        description: 'An unknown error occurred.',
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const TitleBar(title: 'Update Password', hasBackButton: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Input(
                  controller: _emailController,
                  labelText: 'Current Email',
                ),
                const SizedBox(height: 15),
                Input(
                  controller: _passwordController,
                  labelText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 15),
                Input(
                  controller: _newPasswordController,
                  labelText: 'New Password',
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                Button(
                  text: 'Update Password',
                  onPressed: () => _updatePassword(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
