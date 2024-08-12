import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:space_sculpt_mobile_app/src/widgets/title.dart';
import '../../../colors.dart';
import '../../widgets/toast.dart';
import '../../services/auth_service.dart';
import '../../widgets/input.dart';
import '../../widgets/button.dart';

class UpdateEmail extends StatefulWidget {
  const UpdateEmail({super.key});

  @override
  _UpdateEmailState createState() => _UpdateEmailState();
}

class _UpdateEmailState extends State<UpdateEmail> {
  final _emailController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> _updateEmail(BuildContext context) async {
    String email = _emailController.text.trim();
    String newEmail = _newEmailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty || newEmail.isEmpty) {
      Toast.showErrorToast(
        title: 'Error',
        description: 'All fields are required.',
        context: context,
      );
      return;
    }

    if (email == newEmail) {
      Toast.showErrorToast(
        title: 'Error',
        description: 'New email cannot be the same as the current email.',
        context: context,
      );
      return;
    }

    try {
      await _authService.updateEmail(newEmail, password);

      if (!context.mounted) return;

      Toast.showSuccessToast(
        title: 'Success',
        description: 'Email updated successfully.',
        context: context,
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        Toast.showErrorToast(
          title: 'Error',
          description: 'Please re-login to update email.',
          context: context,
        );
      } else if (e.code == 'wrong-password') {
        Toast.showErrorToast(
          title: 'Error',
          description: 'Invalid password.',
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
          const TitleBar(title: 'Update Email', hasBackButton: true),
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
                  controller: _newEmailController,
                  labelText: 'New Email',
                ),
                const SizedBox(height: 15),
                Input(
                  controller: _passwordController,
                  labelText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                Button(
                  text: 'Update Email',
                  onPressed: () => _updateEmail(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
