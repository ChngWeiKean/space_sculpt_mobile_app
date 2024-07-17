import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late DatabaseReference _dbRef;
  User? _currentUser;
  Map<dynamic, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    final snapshot = await _dbRef.child('users/${_currentUser!.uid}').get();
    if (snapshot.exists) {
      setState(() {
        _userData = snapshot.value as Map<dynamic, dynamic>;
        print('User data: $_userData');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${_userData!['name']}'),
      ),
      body: Center(
        child: Text('Hello, ${_userData!['name']}! Your role is ${_userData!['role']}.'),
      ),
    );
  }
}
