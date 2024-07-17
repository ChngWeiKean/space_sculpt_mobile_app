import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../screens/auth/Login.dart';
import '../screens/customer/Homepage.dart';
import '../screens/delivery/Dashboard.dart';

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance.ref().child('users/${user.uid}').get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData && snapshot.data != null) {
                final userData = snapshot.data!.value as Map<dynamic, dynamic>;
                if (userData['role'] == 'Customer') {
                  return const Homepage();
                } else {
                  return const Dashboard();
                }
              }
              return const Login();
            },
          );
        }
        return const Login();
      },
    );
  }
}
