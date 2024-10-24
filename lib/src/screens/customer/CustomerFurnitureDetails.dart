import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../colors.dart';
import '../../widgets/title.dart';
import '../../services/cart_service.dart';
import '../../widgets/toast.dart';
import '../../widgets/ARModelViewer.dart';

class CustomerFurnitureDetails extends StatefulWidget {
  final String id;

  const CustomerFurnitureDetails({super.key, required this.id});

  @override
  _CustomerFurnitureDetailsState createState() => _CustomerFurnitureDetailsState();
}

class _CustomerFurnitureDetailsState extends State<CustomerFurnitureDetails> {
  User? _currentUser;
  late DatabaseReference _dbRef;
  Map<dynamic, dynamic>? _furnitureData;
  String? _mainImage;
  late String _currentModelUrl;
  String? _selectedVariant;
  bool _isInCart = false;
  List<Map<dynamic, dynamic>> _variants = [];
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchData();
  }

  @override
  void dispose() {
    _dbRef.onDisconnect();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchFurniture()]);
  }

  Future<void> _fetchFurniture() async {
    double averageRating = 0.0;
    int ratingCount = 0;
    final snapshot = await _dbRef.child('furniture/${widget.id}').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data['id'] = widget.id;

      final variantsMap = data['variants'] as Map<dynamic, dynamic>? ?? {};
      final variants = variantsMap.entries.map((entry) {
        return {
          'id': entry.key,
          ...entry.value as Map<dynamic, dynamic>
        };
      }).toList();

      if (variants.isNotEmpty) {
        final defaultVariant = variants.firstWhere(
                (variant) => int.parse(variant['inventory'].toString()) > 0,
            orElse: () => variants.first);
        _mainImage = defaultVariant['image'];
        _currentModelUrl = defaultVariant['model'];
        _selectedVariant = defaultVariant['id'];
      }
      _variants = variants;
      data['selectedVariant'] = _currentModelUrl;
      data['order_length'] = (data['orders']?.toList())?.length ?? 0;

      if (data['ratings'] != null && data['ratings'] is List) {
        List ratingsList = data['ratings'];
        ratingCount = ratingsList.length;
        double totalRatings = 0.0;

        for (var rating in ratingsList) {
          if (rating['rating'] != null) {
            totalRatings += double.parse(rating['rating'].toString());
            data['ratingCount'] = totalRatings;
          }
        }

        if (ratingCount > 0) {
          averageRating = totalRatings / ratingCount;
          data['averageRating'] = averageRating;
        }
      }

      if (double.parse(data['discount'].toString()) != 0.0) {
        double price = double.parse(data['price'].toString());
        double discount = double.parse(data['discount'].toString());
        double discountedPrice = price - (price * discount / 100);
        data['discounted_price'] = discountedPrice.toStringAsFixed(2);
      }

      setState(() {
        _furnitureData = data;
        _checkIfInCart();
      });
    } else {
      print('No furniture item found with id ${widget.id}');
    }
  }

  Future<void> _checkIfInCart() async {
    if (_currentUser == null || _selectedVariant == null) {
      return;
    }

    try {
      // Fetch the cart snapshot
      final cartSnapshot = await _dbRef.child('users/${_currentUser!.uid}/cart').get();

      // Check if cart exists and is a Map
      if (cartSnapshot.exists && cartSnapshot.value is Map) {
        final cartData = cartSnapshot.value as Map<dynamic, dynamic>;

        // Use list comprehension and efficient lookups
        bool found = cartData.values.any((cartItem) {
          if (cartItem is Map) {
            return cartItem['furnitureId'] == widget.id &&
                cartItem['variantId'] == _selectedVariant;
          }
          return false;
        });

        setState(() {
          _isInCart = found;
          print('Is in cart: $_isInCart');
        });
      } else {
        setState(() {
          _isInCart = false;
        });
      }
    } catch (e) {
      print('Error checking cart: $e');
      setState(() {
        _isInCart = false;
      });
    }
  }

  Future<void> _addToCart(userId, furnitureId, variantId, BuildContext context) async {
    await _cartService.addToCart(userId, furnitureId, variantId);

    // Show success message
    if (!context.mounted) return;

    Toast.showSuccessToast(title: 'Success',
        description: 'Successfully added to cart.',
        context: context);

    // Update cart status
    _checkIfInCart();
  }

  void _alreadyInCart(BuildContext context) {
    Toast.showInfoToast(title: 'Info',
        description: 'Item already in cart.',
        context: context);
  }

  void _selectVariant(Map<dynamic, dynamic> variant) {
    setState(() {
      _mainImage = variant['image'];
      _currentModelUrl = variant['model'];
      _furnitureData?['selectedVariant'] = variant['color'];
      _selectedVariant = variant['id'];
    });
    _checkIfInCart();
  }

  void _show3DModelModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            width: 300,
            height: 400,
            child: Column(
              children: [
                const Text(
                  '3D Model',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Poppins_Bold',
                  ),
                ),
                Expanded(
                  child: _currentModelUrl != null
                      ? ModelViewer(
                    src: '$_currentModelUrl',
                    alt: '3D Model',
                    ar: true,
                    autoRotate: true,
                    disableZoom: true,
                  )
                      : const Center(
                    child: Text(
                      'No 3D Model Available',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins_Medium',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _furnitureData == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TitleBar(
                title: '${_furnitureData?['name'] ?? 'Product'}',
                hasBackButton: true,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        _mainImage != null
                            ? Image.network(
                          _mainImage!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.contain,
                        )
                            : Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey,
                          child: const Center(
                            child: Text(
                              'No Image',
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: 'Poppins_Semibold',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        padding: const EdgeInsets.only(top: 16, bottom: 90),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _variants.isNotEmpty
                                    ? SizedBox(
                                  height: 85,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _variants.length,
                                    itemBuilder: (context, index) {
                                      final variant = _variants[index];
                                      final isOutOfStock = int.parse(variant['inventory'].toString()) == 0;
                                      return GestureDetector(
                                        onTap: isOutOfStock
                                            ? null
                                            : () => _selectVariant(variant),
                                        child: Stack(
                                          children: [
                                            ColorFiltered(
                                              colorFilter: const ColorFilter.mode(
                                                  Colors.transparent, BlendMode.multiply),
                                              child: Container(
                                                width: 80,
                                                padding: const EdgeInsets.only(top: 8, bottom: 8),
                                                margin: const EdgeInsets.only(right: 8),
                                                decoration: BoxDecoration(
                                                  color: variant['model'] == _currentModelUrl
                                                      ? AppColors.primary
                                                      : Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Image.network(
                                                      variant['image'],
                                                      height: 40,
                                                      fit: BoxFit.contain,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      variant['color'] ?? 'Unknown',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (isOutOfStock)
                                              Center(
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  color: Colors.red,
                                                  child: const Text(
                                                    'Out of Stock',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontFamily: 'Poppins_Bold',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                )
                                    : const Center(child: Text('No Variants Available')),
                                const SizedBox(height: 20),
                                Text(
                                  _furnitureData?['name'] ?? 'No Name available',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins_Bold',
                                    letterSpacing: 1.1,
                                    fontSize: 20,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Row(
                                      children: List.generate(5, (index) {
                                        double averageRating = _furnitureData?['averageRating'] ?? 0.0;
                                        return Icon(
                                          index < averageRating ? Icons.star : Icons.star_border,
                                          color: Colors.amber,
                                          size: 20,
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${(_furnitureData?['averageRating'] ?? 0).toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins_Medium',
                                        fontSize: 14,
                                        color: Colors.amber,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '(${_furnitureData?['ratingCount'] ?? 0} reviews)',
                                      style: TextStyle(
                                        fontFamily: 'Poppins_Medium',
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.favorite_border,
                                          size: 20,
                                          color: Colors.red
                                      ),
                                      onPressed: () {
                                        // Add to favorites
                                      },
                                    ),
                                  ],
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.grey[300],
                                  thickness: 1,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontFamily: 'Poppins_Semibold',
                                    fontSize: 15,
                                    color: Colors.grey[900]
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _furnitureData?['description'] ??
                                      'No description available',
                                  style: TextStyle(
                                    fontFamily: 'Poppins_Regular',
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Size',
                                  style: TextStyle(
                                      fontFamily: 'Poppins_Semibold',
                                      fontSize: 15,
                                      color: Colors.grey[900]
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(
                                      'Width: ',
                                      style: TextStyle(
                                        fontFamily: 'Poppins_Regular',
                                        fontSize: 14,
                                        color: Colors.grey[900],
                                      ),
                                    ),
                                    Text(
                                      '${_furnitureData?['width'] ?? '0'} cm',
                                      style: TextStyle(
                                        fontFamily: 'Poppins_Regular',
                                        fontSize: 12,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Height: ',
                                      style: TextStyle(
                                        fontFamily: 'Poppins_Regular',
                                        fontSize: 14,
                                        color: Colors.grey[900],
                                      ),
                                    ),
                                    Text(
                                      '${_furnitureData?['height'] ?? '0'} cm',
                                      style: TextStyle(
                                        fontFamily: 'Poppins_Regular',
                                        fontSize: 12,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Length: ',
                                      style: TextStyle(
                                        fontFamily: 'Poppins_Regular',
                                        fontSize: 14,
                                        color: Colors.grey[900],
                                      ),
                                    ),
                                    Text(
                                      '${_furnitureData?['length'] ?? '0'} cm',
                                      style: TextStyle(
                                        fontFamily: 'Poppins_Regular',
                                        fontSize: 12,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'How to Care',
                                  style: TextStyle(
                                    fontFamily: 'Poppins_Semibold',
                                    fontSize: 15,
                                    color: Colors.grey[900]
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _furnitureData?['care_method'] ??
                                      'No care instructions available',
                                  style: TextStyle(
                                    fontFamily: 'Poppins_Regular',
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Divider(
                                  height: 1,
                                  color: Colors.grey[300],
                                  thickness: 1,
                                ),
                                const SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reviews',
                                      style: TextStyle(
                                        fontFamily: 'Poppins_Semibold',
                                        fontSize: 15,
                                        color: Colors.grey[900],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _furnitureData?['reviews'] != null && _furnitureData?['reviews'].isNotEmpty
                                        ? Column(
                                      children: _furnitureData?['reviews'].entries.map<Widget>((entry) {
                                        final review = entry.value;
                                        final userName = review['user']?['name'] ?? 'Anonymous';
                                        final userImage = review['user']?['profile_picture'] ?? '';
                                        final rating = review['rating'] ?? 0;
                                        final reviewText = review['review'] ?? 'No review available';

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 5.0), // Add padding between reviews
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: userImage.isNotEmpty ? NetworkImage(userImage) : null,
                                                radius: 13,
                                                child: userImage.isEmpty
                                                    ? const Icon(
                                                  Icons.person,
                                                  size: 16,
                                                  color: AppColors.secondary,
                                                )
                                                    : null,
                                              ),
                                              const SizedBox(width: 10), // Add space between avatar and text
                                              Flexible(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Flexible( // Ensure that the username wraps
                                                          child: Text(
                                                            userName,
                                                            style: TextStyle(
                                                              fontFamily: 'Poppins_Semibold',
                                                              fontSize: 12,
                                                              color: Colors.grey[900],
                                                            ),
                                                            overflow: TextOverflow.ellipsis, // Prevent overflow
                                                          ),
                                                        ),
                                                        const SizedBox(width: 5),
                                                        Row(
                                                          children: List.generate(5, (starIndex) {
                                                            return Icon(
                                                              starIndex < rating ? Icons.star : Icons.star_border,
                                                              color: Colors.amber,
                                                              size: 14,
                                                            );
                                                          }),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      reviewText,
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins_Regular',
                                                        fontSize: 10,
                                                        color: Colors.grey[800],
                                                      ),
                                                      maxLines: 3, // Limit review text to 3 lines
                                                      overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
                                                    ),
                                                    const SizedBox(height: 10),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    )
                                        : const Center(
                                      child: Text('No reviews available'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding (
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Container(
                padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8, left: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.view_in_ar,
                          color: AppColors.secondary, size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ARModelViewer(furnitureData: _furnitureData, selectedVariant: _selectedVariant),
                          ),
                        );
                      },
                      // onPressed: _show3DModelModal,
                    ),
                    _furnitureData?['discounted_price'] != null
                        ? Row(
                      verticalDirection: VerticalDirection.up,
                      children: [
                        Text(
                          'RM ${_furnitureData?['discounted_price'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontFamily: 'Poppins_Bold',
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_furnitureData?['price'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontFamily: 'Poppins_Medium',
                            fontSize: 13,
                            color: Colors.red,
                            decoration:
                            TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    )
                        : Text(
                      'RM ${_furnitureData?['price'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontFamily: 'Poppins_Bold',
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isInCart
                          ? () => _alreadyInCart(context)
                          : () {
                        if (_currentUser != null && _selectedVariant != null) {
                          _addToCart(_currentUser!.uid, widget.id, _selectedVariant, context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isInCart ? AppColors.success : AppColors.secondary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(36),
                        ),
                      ),
                      child: Text(
                        _isInCart ? 'In Cart' : 'Add to Cart',
                        style: const TextStyle(
                          fontFamily: 'Poppins_Semibold',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ),
        ],
      ),
    );
  }
}