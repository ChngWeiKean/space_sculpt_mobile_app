import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/src/widgets/button.dart';
import 'package:space_sculpt_mobile_app/src/widgets/toast.dart';
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
  final List<Map<dynamic, dynamic>> _cartItems = [];
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
      } else {
        _cartData = null;
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
          if (double.parse(furnitureData['discount'].toString()) != 0.0) {
            double price = double.parse(furnitureData['price'].toString());
            double discount = double.parse(furnitureData['discount'].toString());
            double discountedPrice = price - (price * discount / 100);
            furnitureData['discounted_price'] = discountedPrice.toStringAsFixed(2);
          }
          var variantData = variantSnapshot.value as Map<dynamic, dynamic>;
          _cartItems.add({
            'cartId': key,
            'quantity': cartItem['quantity'],
            'added_on': cartItem['created_on'],
            'image': variantData['image'],
            'color': variantData['color'],
            'inventory': variantData['inventory'],
            'variantId': cartItem['variantId'],
            'id': furnitureSnapshot.key,
            ...furnitureData,
          });
        }
      }
    }
  }

  void _goShopping() {
    Navigator.pushNamed(context, Routes.homepage);
  }

  void _handleCheckout() {
    List<Map<dynamic, dynamic>> availableItems = _cartItems.where((item) {
      return int.parse(item['inventory'].toString()) > 0;
    }).toList();

    print(availableItems.length);

    if (availableItems.isEmpty) {
      // Show a message if no items are available for checkout
      Toast.showInfoToast(title: 'No Items Available', description: 'All items in your cart are out of stock.', context: context);
      return;
    }

    // Navigate to the checkout page with available items
    Navigator.pushNamed(
      context,
      Routes.customerCheckout,
      arguments: availableItems,
    );
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
              if (!context.mounted) return;
              Toast.showSuccessToast(title: 'Success', description: 'Successfully removed item from cart', context: context);
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
    bool isOutOfStock = item['inventory'] == 0;

    return Column(
      children: [
        ListTile(
          leading: Image.network(
            item['image'],
            fit: BoxFit.contain,
            width: 100,
            height: 100,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins_Bold',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black, size: 20),
                onPressed: () => _removeFromCart(item['cartId']),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item['color']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins_SemiBold',
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  item['discounted_price'] != null
                      ? Row(
                    children: [
                      Text(
                        'RM ${item['discounted_price']}',
                        style: const TextStyle(
                          fontFamily: 'Poppins_Medium',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'RM ${item['price']}',
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
                    'RM ${item['price']}',
                    style: const TextStyle(
                      fontFamily: 'Poppins_Medium',
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 15),
                        onPressed: () {
                          if (item['quantity'] > 1) {
                            _updateQuantity(item['cartId'], item['quantity'] - 1);
                          }
                        },
                      ),
                      Text('${item['quantity']}'),
                      IconButton(
                        icon: const Icon(Icons.add, size: 15),
                        onPressed: () {
                          // Check if the quantity exceeds the available inventory
                          if (int.parse(item['quantity'].toString()) >= int.parse(item['inventory'].toString())) {
                            Toast.showInfoToast(
                              title: 'Out of Stock',
                              description: 'You have reached the maximum quantity available for this item.',
                              context: context,
                            );
                            return;
                          }
                          _updateQuantity(item['cartId'], item['quantity'] + 1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          trailing: isOutOfStock
              ? Container(
            color: Colors.red,
            padding: const EdgeInsets.all(4.0),
            child: const Text(
              'Out of Stock',
              style: TextStyle(color: Colors.white, fontFamily: 'Poppins_Bold'),
            ),
          )
              : null,
        ),
        Divider(height: 0, color: Colors.grey[300]),
      ],
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
      if (item['inventory'] == 0) {
        return sum; // Exclude out-of-stock items from total
      }

      double itemPrice = item['discounted_price'] != null
          ? double.parse(item['discounted_price'].toString())
          : double.parse(item['price'].toString());
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
              _handleCheckout();
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
