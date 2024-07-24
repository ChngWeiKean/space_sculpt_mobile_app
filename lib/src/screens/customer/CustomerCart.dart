import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/src/widgets/button.dart';
import '../../widgets/customerBottomNavBar.dart';
import '../../../routes.dart';
import '../../services/cart_service.dart';

class CustomerCart extends StatefulWidget {
  const CustomerCart({super.key});

  @override
  _CustomerCartState createState() => _CustomerCartState();
}

class _CustomerCartState extends State<CustomerCart> {
  User? _currentUser;
  Map<dynamic, dynamic>? _cartData;
  late DatabaseReference _dbRef;
  bool _isLoading = true;
  List<Map<dynamic, dynamic>> _cartItems = [];
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchCartData();
  }

  @override
  void dispose() {
    _dbRef.onDisconnect();
    super.dispose();
  }

  Future<void> _fetchCartData() async {
    if (_currentUser != null) {
      final snapshot = await _dbRef.child('users/${_currentUser!.uid}/cart').get();
      if (snapshot.exists) {
        _cartData = snapshot.value as Map<dynamic, dynamic>;
        await _fetchCartItems();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchCartItems() async {
    _cartItems.clear(); // Clear the list before fetching new items
    if (_cartData != null) {
      for (var key in _cartData!.keys) {
        var cartItem = _cartData![key];
        var furnitureSnapshot = await _dbRef.child('furniture/${cartItem['furnitureId']}').get();
        var variantSnapshot = await _dbRef.child('furniture/${cartItem['furnitureId']}/variants/${cartItem['variantId']}').get();
        if (furnitureSnapshot.exists && variantSnapshot.exists) {
          var furnitureData = furnitureSnapshot.value as Map<dynamic, dynamic>;
          if (double.parse(furnitureData['discount']) != 0.0) {
            double price = double.parse(furnitureData['price'].toString());
            double discount = double.parse(furnitureData['discount'].toString());
            double discountedPrice = price - (price * discount / 100);
            furnitureData['discounted_price'] = discountedPrice.toStringAsFixed(2);
          }
          var variantData = variantSnapshot.value as Map<dynamic, dynamic>;
          _cartItems.add({
            'id': key,
            'furnitureData': furnitureData,
            'variantData': variantData,
            'quantity': cartItem['quantity'],
          });
        }
      }
    }
  }

  void _goShopping() {
    Navigator.pushNamed(context, Routes.homepage);
  }

  void _removeFromCart(String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: const Text('Are you sure you want to remove this item from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _cartService.removeFromCart(itemId);
              _fetchCartData();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(String itemId, int newQuantity) async {
    await _cartService.updateCartQuantity(itemId, newQuantity);
    _fetchCartData();
  }

  Widget _buildCartItem(Map<dynamic, dynamic> item) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(item['variantData']['image'], fit: BoxFit.contain, width: 100, height: 100),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(item['furnitureData']['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Poppins_Bold',
                            )
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black, size: 25),
                        onPressed: () => _removeFromCart(item['id']),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['variantData']['color']}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins_SemiBold',
                              )
                          ),
                          item['furnitureData']['discounted_price'] != null
                              ? Row(
                            verticalDirection: VerticalDirection.up,
                            children: [
                              Text(
                                'RM ${item['furnitureData']['discounted_price']}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins_Medium',
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'RM ${item['furnitureData']['price']}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins_Medium',
                                  fontSize: 11,
                                  color: Colors.red,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          )
                              : Text(
                            'RM ${item['furnitureData']['price']}',
                            style: const TextStyle(
                              fontFamily: 'Poppins_Medium',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 20),
                                  onPressed: () {
                                    if (item['quantity'] > 1) {
                                      _updateQuantity(item['id'], item['quantity'] - 1);
                                    }
                                  },
                                ),
                                Text('${item['quantity']}'),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  onPressed: () {
                                    _updateQuantity(item['id'], item['quantity'] + 1);
                                  },
                                ),
                              ]
                          )
                        ],
                      ),
                    ]
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList() {
    if (_cartItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Oops, Your Shopping Cart is Empty', style: TextStyle(fontSize: 16, fontFamily: 'Poppins_Bold')),
              const SizedBox(height: 10),
              const Text('Browse our awesome deals now!', style: TextStyle(fontSize: 12, fontFamily: 'Poppins_Medium')),
              const SizedBox(height: 20),
              Button(
                onPressed: _goShopping,
                text: 'Go Shopping Now',
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        return _buildCartItem(_cartItems[index]);
      },
    );
  }

  Widget _buildOrderSummary() {
    if (_cartItems.isEmpty) {
      return const SizedBox.shrink(); // Returns an empty widget if the cart is empty
    }

    double total = _cartItems.fold(0, (sum, item) {
      double itemPrice = item['furnitureData']['discounted_price'] != null
          ? double.parse(item['furnitureData']['discounted_price'].toString())
          : double.parse(item['furnitureData']['price'].toString());
      return sum + (itemPrice * item['quantity']);
    });

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Order Summary', style: TextStyle(fontSize: 18, fontFamily: 'Poppins_Bold')),
          const SizedBox(height: 10),
          Text('Total: RM${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontFamily: 'Poppins_Medium')),
          const SizedBox(height: 10),
          Button(
            onPressed: () {
              // Handle checkout
            },
            text: 'Proceed to Checkout',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: _buildCartList(),
          ),
          _buildOrderSummary(),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNavBar(initialIndex: 1),
    );
  }
}
