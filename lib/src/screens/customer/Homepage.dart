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

  String get headerImage => 'lib/src/assets/Landing_Header_Image.jpg';

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.asset(
                  headerImage,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.fill,
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Make Your',
                            style: TextStyle(
                              fontSize: 30,
                              fontFamily: 'Poppins_Semibold',
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Interior',
                            style: TextStyle(
                              fontSize: 30,
                              fontFamily: 'Poppins_Semibold',
                              color: Color(0xFFD69511),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Unique & Modern',
                        style: TextStyle(
                          fontSize: 30,
                          fontFamily: 'Poppins_Semibold',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Transform Your Space, One Piece at a Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[100],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Hello, ${_userData!['name']}! Your role is ${_userData!['role']}.',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
