import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/colors.dart';
import 'package:space_sculpt_mobile_app/src/widgets/customerBottomNavBar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late DatabaseReference _dbRef;
  User? _currentUser;
  Map<dynamic, dynamic>? _userData;
  List<Map<dynamic, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchUserData(), _fetchCategories()]);
  }

  Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      final snapshot = await _dbRef.child('users/${_currentUser!.uid}').get();
      if (snapshot.exists) {
        _userData = snapshot.value as Map<dynamic, dynamic>;
      }
    }
  }

  Future<void> _fetchCategories() async {
    final snapshot = await _dbRef.child('categories').get();
    if (snapshot.exists) {
      final categoriesData = snapshot.value as Map<dynamic, dynamic>;
      _categories = categoriesData.entries.map((entry) {
        return {'name': entry.key, ...entry.value as Map};
      }).toList();
    }
  }

  String get headerImage => 'lib/src/assets/Landing_Header_Image.jpg';

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
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Image.asset(
                        headerImage,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.fill,
                      ),
                      const Positioned(
                        top: 50,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Make Your',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontFamily: 'Poppins_Semibold',
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Interior',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontFamily: 'Poppins_Bold',
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Unique & Modern',
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: 'Poppins_Semibold',
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Transform Your Space,',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Poppins_Medium',
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'One Piece at a Time',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Poppins_Medium',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Poppins_Bold',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 120,
                      child: _categories.isEmpty
                          ? const Center(child: Text('No categories available.'))
                          : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 2,
                                  spreadRadius: 0.5,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  category['image'],
                                  height: 80,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  category['name'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Poppins_Medium',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      bottomNavigationBar: const CustomerBottomNavBar(initialIndex: 0),
    );
  }
}
