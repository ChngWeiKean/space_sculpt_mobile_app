import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/colors.dart';
import 'package:space_sculpt_mobile_app/src/widgets/customerBottomNavBar.dart';
import '../../../routes.dart';
import '../../widgets/furnitureCard.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late DatabaseReference _dbRef;
  User? _currentUser;
  List<Map<dynamic, dynamic>> _categories = [];
  List<Map<dynamic, dynamic>> _furniture = [];
  List<Map<dynamic, dynamic>> _topFurniture = [];

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _categories.clear();
    _furniture.clear();
    _topFurniture.clear();
    _dbRef.onDisconnect();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchUserData(), _fetchCategories(), _fetchFurniture()]);
  }

  Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      final snapshot = await _dbRef.child('users/${_currentUser!.uid}').get();
      if (snapshot.exists) {
      }
    }
  }

  Future<void> _fetchCategories() async {
    final snapshot = await _dbRef.child('categories').get();
    if (snapshot.exists) {
      final categoriesData = snapshot.value as Map<dynamic, dynamic>;
      _categories = categoriesData.entries.map((entry) {
        return {'id': entry.key, ...entry.value as Map};
      }).toList();
    }
  }

  Future<void> _fetchFurniture() async {
    final snapshot = await _dbRef.child('furniture').get();
    if (snapshot.exists) {
      final List<Map<dynamic, dynamic>> fetchedFurniture = [];
      final furnitureData = snapshot.value as Map<dynamic, dynamic>;

      furnitureData.forEach((key, value) {
        try {
          final data = value as Map<dynamic, dynamic>;
          data['id'] = key;

          final variants = (data['variants'] as Map<dynamic, dynamic>?)?.values.toList() ?? [];
          data['mainImage'] = variants.isNotEmpty
              ? variants.firstWhere(
                  (variant) => int.parse(variant['inventory'].toString()) > 0,
              orElse: () => variants.first)['image']
              : null;
          data['selectedVariant'] = variants.isNotEmpty
              ? variants.firstWhere(
                  (variant) => int.parse(variant['inventory'].toString()) > 0,
              orElse: () => variants.first)['color']
              : null;
          data['order_length'] = (data['orders']?.toList())?.length ?? 0;
          fetchedFurniture.add(data);
        } catch (e) {
          print('Error processing furniture item with key $key: $e');
        }
      });

      fetchedFurniture.sort((a, b) => b['order_length'].compareTo(a['order_length']));

      _furniture = fetchedFurniture.toList();
      _topFurniture = fetchedFurniture.take(10).toList();
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
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
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
                        const SizedBox(height: 20),
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
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, Routes.customerCategoryDetails, arguments: category['id']);
                                  },
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: AppColors.shadow,
                                          blurRadius: 6,
                                          spreadRadius: 2,
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
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Popular Items',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Poppins_Bold',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _topFurniture.isEmpty
                              ? const Center(child: Text('No furniture available.'))
                              : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(0.0),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, // 2 cards per row
                                  crossAxisSpacing: 8.0,
                                  mainAxisSpacing: 8.0,
                                  childAspectRatio: 0.7,
                                ),
                                itemCount: _topFurniture.length,
                                itemBuilder: (context, index) {
                                  return FurnitureCard(data: _topFurniture[index]);
                                },
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: const CustomerBottomNavBar(initialIndex: 0),
    );
  }
}
