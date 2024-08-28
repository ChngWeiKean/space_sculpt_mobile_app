import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:space_sculpt_mobile_app/src/widgets/button.dart';
import 'package:space_sculpt_mobile_app/src/widgets/titleSearchFilter.dart';

import '../../../colors.dart';
import '../../widgets/furnitureCard.dart';

class CustomerCategoryDetails extends StatefulWidget {
  final String id;

  const CustomerCategoryDetails({required this.id, super.key});

  @override
  _CustomerCategoryDetailsState createState() => _CustomerCategoryDetailsState();
}

class _CustomerCategoryDetailsState extends State<CustomerCategoryDetails> {
  final _dbRef = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  final List<Map<dynamic, dynamic>> _furnitureList = [];
  final List<String> _materials = [];
  final List<String> _colors = [];
  User? _currentUser;
  Map<dynamic, dynamic>? _categoryData;
  List<Map<dynamic, dynamic>> _filteredFurnitureList = [];
  List<Map<String, String>> _subcategories = [];
  String? _selectedSubcategory;
  bool _isLoading = true;
  String _searchQuery = '';
  String? _priceRange;
  String? _material;
  String? _color;
  String? _sortBy;
  bool _filterByFavourites = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchData();
  }

  Future<void> _fetchData() async {
    final snapshot = await _dbRef.child('categories/${widget.id}').get();
    if (snapshot.exists) {
      _categoryData = snapshot.value as Map<dynamic, dynamic>;
      await _fetchSubcategories();
    }
  }

  Future<void> _fetchSubcategories() async {
    final subcategoriesSnapshot = await _dbRef.child('categories/${widget.id}/subcategories').get();
    if (subcategoriesSnapshot.exists) {
      final subcategoryIds = (subcategoriesSnapshot.value as List<dynamic>).cast<String>();
      for (final subcategoryId in subcategoryIds) {
        await _fetchFurnitureIds(subcategoryId);
        final subcategorySnapshot = await _dbRef.child('subcategories/$subcategoryId').get();
        if (subcategorySnapshot.exists) {
          final subcategoryData = subcategorySnapshot.value as Map<dynamic, dynamic>;
          _subcategories.add({
            'id': subcategoryId,
            'name': subcategoryData['name'],
          });
        }
      }
    }
    setState(() {
      _isLoading = false;
      _filteredFurnitureList = List.from(_furnitureList); // Initial filter
    });
  }

  Future<void> _fetchFurnitureIds(String subcategoryId) async {
    final furnitureIdsSnapshot = await _dbRef.child('subcategories/$subcategoryId/furniture').get();
    if (furnitureIdsSnapshot.exists) {
      final furnitureIds = (furnitureIdsSnapshot.value as List<dynamic>).cast<String>();
      for (final furnitureId in furnitureIds) {
        await _fetchFurnitureData(furnitureId);
      }
    }
  }

  Future<void> _fetchFurnitureData(String furnitureId) async {
    final furnitureSnapshot = await _dbRef.child('furniture/$furnitureId').get();
    if (furnitureSnapshot.exists) {
      final furnitureData = furnitureSnapshot.value as Map<dynamic, dynamic>;
      try {
        furnitureData['id'] = furnitureSnapshot.key;

        final variants = (furnitureData['variants'] as Map<dynamic, dynamic>?)?.values.toList() ?? [];
        furnitureData['mainImage'] = variants.isNotEmpty
            ? variants.firstWhere(
                (variant) => int.parse(variant['inventory'].toString()) > 0,
            orElse: () => variants.first)['image']
            : null;
        furnitureData['selectedVariant'] = variants.isNotEmpty
            ? variants.firstWhere(
                (variant) => int.parse(variant['inventory'].toString()) > 0,
            orElse: () => variants.first)['color']
            : null;
        furnitureData['order_length'] = (furnitureData['orders']?.toList())?.length ?? 0;

        if (furnitureData['ratings'] != null && furnitureData['ratings'] is List) {
          List ratingsList = furnitureData['ratings'];
          furnitureData['ratingCount'] = ratingsList.length;
          double totalRatings = 0.0;

          for (var rating in ratingsList) {
            if (rating['rating'] != null) {
              totalRatings += double.parse(rating['rating'].toString());
            }
          }

          if (furnitureData['ratingCount'] > 0) {
            furnitureData['averageRatings'] = totalRatings / furnitureData['ratingCount'];
          }
        }

        if (!_materials.contains(furnitureData['material'])) {
          _materials.add(furnitureData['material']);
        }
        for (var variant in variants) {
          final trimmedColor = variant['color'].trim();
          if (!_colors.contains(trimmedColor)) {
            _colors.add(trimmedColor);
          }
        }

        // Check if the furniture item is a favourite
        final userFavourites = await _fetchUserFavourites();
        furnitureData['isFavourite'] = userFavourites.contains(furnitureData['id']);

        print('Furniture data: $furnitureData');
        _furnitureList.add(furnitureData);
      } catch (e) {
        print('Error processing furniture item with key ${furnitureSnapshot.key}: $e');
      }
    }
  }

  Future<List<String>> _fetchUserFavourites() async {
    if (_currentUser == null) return [];
    final userSnapshot = await _dbRef.child('users/${_currentUser!.uid}/favourites').get();
    if (userSnapshot.exists) {
      return List<String>.from(userSnapshot.value as List<dynamic>);
    }
    return [];
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price Range Filter Dropdown
                  DropdownButtonFormField<String>(
                    value: _priceRange,
                    decoration: InputDecoration(
                      labelText: 'Filter by Price Range',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    items: <String>[
                      'Any', // Empty value option
                      ...priceRangeFilter.keys
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value == 'Any' ? null : value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _priceRange = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  // Material Filter Dropdown
                  DropdownButtonFormField<String>(
                    value: _material,
                    decoration: InputDecoration(
                      labelText: 'Filter by Material',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    items: <String>[
                      'Any', // Empty value option
                      ..._materials
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value == 'Any' ? null : value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _material = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  // Color Filter Dropdown
                  DropdownButtonFormField<String>(
                    value: _color,
                    decoration: InputDecoration(
                      labelText: 'Filter by Color',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    items: <String>[
                      'Any', // Empty value option
                      ..._colors
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value == 'Any' ? null : value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _color = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  // Sort By Dropdown
                  DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: const InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(),
                    ),
                    items: <String>[
                      'Any', // Empty value option
                      'price_ascending',
                      'price_descending',
                      'ratings',
                      'height',
                      'length',
                      'width'
                    ].map<DropdownMenuItem<String>>((String value) {
                      String label;
                      switch (value) {
                        case 'Any':
                          label = 'Any';
                          break;
                        case 'price_ascending':
                          label = 'Price: Low to High';
                          break;
                        case 'price_descending':
                          label = 'Price: High to Low';
                          break;
                        case 'ratings':
                          label = 'Ratings: Highest First';
                          break;
                        case 'height':
                          label = 'Height: Low to High';
                          break;
                        case 'length':
                          label = 'Length: Low to High';
                          break;
                        case 'width':
                          label = 'Width: Low to High';
                          break;
                        default:
                          label = 'Any';
                      }
                      return DropdownMenuItem<String>(
                        value: value == 'Any' ? null : value,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _sortBy = newValue;
                      });
                    },
                  ),
                  // Filter by Favourites Checkbox
                  CheckboxListTile(
                    title: const Text('Filter by Favourites'),
                    value: _filterByFavourites,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _filterByFavourites = newValue ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Button(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _applyFilters();
                    },
                    text: 'Apply Filters',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    List<Map<dynamic, dynamic>> filteredList = List.from(_furnitureList);

    // Search query filter
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((item) {
        return item['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item['description'].toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Subcategory filter
    if (_selectedSubcategory != null) {
      filteredList = filteredList.where((item) {
        return item['subcategory'] == _selectedSubcategory;
      }).toList();
    }

    // Price Range filter
    if (_priceRange != null && _priceRange != 'Any') {
      filteredList = filteredList.where((item) {
        final price = double.tryParse(item['price'].toString()) ?? 0.0;
        final range = priceRangeFilter[_priceRange]!;
        return price >= range['min'] && price <= range['max'];
      }).toList();
    }

    // Material filter
    if (_material != null && _material != 'Any') {
      filteredList = filteredList.where((item) => item['material'] == _material).toList();
    }

    // Color filter
    if (_color != null && _color != 'Any') {
      filteredList = filteredList.where((item) {
        return item['selectedVariant'] != null &&
            item['selectedVariant'].toString().toLowerCase() == _color!.toLowerCase();
      }).toList();
    }

    // Favourites filter
    if (_filterByFavourites) {
      filteredList = filteredList.where((item) => item['isFavourite'] == true).toList();
    }

    // Sort
    if (_sortBy != null) {
      switch (_sortBy) {
        case 'price_ascending':
          filteredList.sort((a, b) => (double.parse(a['price'].toString()) - double.parse(b['price'].toString())).toInt());
          break;
        case 'price_descending':
          filteredList.sort((a, b) => (double.parse(b['price'].toString()) - double.parse(a['price'].toString())).toInt());
          break;
        case 'ratings':
          filteredList.sort((a, b) => (b['averageRatings'] as double? ?? 0.0).compareTo(a['averageRatings'] as double? ?? 0.0));
          break;
        case 'height':
          filteredList.sort((a, b) => (double.parse(a['height'].toString()) - double.parse(b['height'].toString())).toInt());
          break;
        case 'length':
          filteredList.sort((a, b) => (double.parse(a['length'].toString()) - double.parse(b['length'].toString())).toInt());
          break;
        case 'width':
          filteredList.sort((a, b) => (double.parse(a['width'].toString()) - double.parse(b['width'].toString())).toInt());
          break;
      }
    }

    setState(() {
      _filteredFurnitureList = filteredList;
    });
  }

  final Map<String, Map<String, dynamic>> priceRangeFilter = {
    'Below RM100': {'min': 0, 'max': 100},
    'RM100 - RM500': {'min': 100, 'max': 500},
    'RM500 - RM1000': {'min': 500, 'max': 1000},
    'Above RM1000': {'min': 1000, 'max': double.infinity},
  };

  Widget _buildSubcategoryButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding here
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSubcategory = null;
                  _applyFilters();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                margin: const EdgeInsets.only(right: 8.0),
                decoration: BoxDecoration(
                  color: _selectedSubcategory == null ? AppColors.secondary : Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                      color: _selectedSubcategory == null ? AppColors.secondary : Colors.grey),
                ),
                child: Text(
                  'All',
                  style: TextStyle(color: _selectedSubcategory == null ? Colors.white : AppColors.tertiary),
                ),
              ),
            ),
            ..._subcategories.map((subcategory) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSubcategory = subcategory['id'];
                    _applyFilters();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  margin: const EdgeInsets.only(right: 8.0),
                  decoration: BoxDecoration(
                    color: _selectedSubcategory == subcategory['id'] ? AppColors.secondary : Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                        color: _selectedSubcategory == subcategory['id'] ? AppColors.secondary : Colors.grey),
                  ),
                  child: Text(
                    subcategory['name']!,
                    style: TextStyle(color: _selectedSubcategory == subcategory['id'] ? Colors.white : AppColors.tertiary),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TitleWithSearchAndFilter(
            hasBackButton: true,
            onSearch: _onSearch,
            onFilter: _onFilter,
          ),
          _buildSubcategoryButtons(),
          const SizedBox(height: 20.0),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _filteredFurnitureList.isEmpty
                  ? const Center(child: Text('No furniture available.'))
                  : GridView.builder(
                padding: const EdgeInsets.all(0.0),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 cards per row
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.7,
                ),
                itemCount: _filteredFurnitureList.length,
                itemBuilder: (context, index) {
                  return FurnitureCard(
                      data: _filteredFurnitureList[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
