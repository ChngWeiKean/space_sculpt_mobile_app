import 'package:firebase_database/firebase_database.dart';

class CheckoutService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> data) async {
    final String userId = data['user'];
    final List<Map<dynamic, dynamic>> items = List<Map<dynamic, dynamic>>.from(data['items']);
    final Map<dynamic, dynamic> address = data['address'];
    final String payment = data['payment'];
    final String paymentMethod = data['payment_method'];
    final String subtotal = data['subtotal'];
    final String shipping = data['shipping'];
    final String weight = data['weight'];
    final String discount = data['discount'];
    final Map<dynamic, dynamic>? voucher = data['voucher'];
    final String total = data['total'];
    final String shippingDate = data['shipping_date'];
    final String shippingTime = data['shipping_time'];
    final String remarks = data['remarks'];

    try {
      // Fetch existing order IDs and determine the max order ID
      final DatabaseReference ordersRef = _dbRef.child('orders');
      final DataSnapshot ordersSnapshot = await ordersRef.get();
      int maxOrderId = 0;

      if (ordersSnapshot.exists) {
        final Map<dynamic, dynamic> orders = ordersSnapshot.value as Map<dynamic, dynamic>;
        orders.forEach((orderKey, orderValue) {
          final int orderId = int.parse(orderValue['order_id'].replaceAll('OID', ''));
          if (orderId > maxOrderId) {
            maxOrderId = orderId;
          }
        });
      }

      // Generate new order ID
      final String newOrderId = 'OID${maxOrderId + 1}';

      // Create a new order reference with auto-generated key
      final DatabaseReference newOrderRef = ordersRef.push();
      final String? newOrderKey = newOrderRef.key;

      // Prepare the order data with the generated order ID
      final Map<String, dynamic> orderData = {
        'order_id': newOrderId,
        'user_id': userId,
        'items': items,
        'address': address,
        'payment': payment,
        'payment_method': paymentMethod,
        'subtotal': subtotal,
        'shipping': shipping,
        'weight': weight,
        'discount': discount,
        'voucher': voucher,
        'total': total,
        'shipping_date': shippingDate,
        'shipping_time': shippingTime,
        'remarks': remarks,
        'completion_status': {
          'Pending': DateTime.now().toIso8601String(),
          'ReadyForShipping': null,
          'Shipping': null,
          'Arrived': null,
          'Completed': null
        },
        'created_on': DateTime.now().toIso8601String()
      };

      // Set the order data to the new order reference
      await newOrderRef.set(orderData);

      // If voucher is applied, add order_id to the voucher/orders
      if (voucher != null) {
        try {
          final DatabaseReference voucherRef = _dbRef.child('vouchers/${voucher['id']}/orders');

          // Get current orders array (if any)
          final DataSnapshot voucherSnapshot = await voucherRef.get();
          List<dynamic> currentOrders = [];
          if (voucherSnapshot.exists) {
            currentOrders = List<dynamic>.from(voucherSnapshot.value as List);
          }

          // Append the new order_id to the current orders array
          currentOrders.add(newOrderKey);

          // Update the database with the updated orders array
          await voucherRef.set(currentOrders);

          // Update the user's voucher to be redeemed
          final DatabaseReference userVoucherRef = _dbRef.child('users/$userId/vouchers/${voucher['id']}');
          await userVoucherRef.set(false);

          // Update the voucher's user to be redeemed
          final DatabaseReference voucherUserRef = _dbRef.child('vouchers/${voucher['id']}/users/$userId');
          await voucherUserRef.set(false);
        } catch (error) {
          print('Error adding order to voucher: $error');
        }
      }

      // Store order id in user/orders
      try {
        final DatabaseReference userOrderRef = _dbRef.child('users/$userId/orders');
        final DataSnapshot userOrderSnapshot = await userOrderRef.get();
        List<dynamic> userOrders = [];
        if (userOrderSnapshot.exists) {
          userOrders = List<dynamic>.from(userOrderSnapshot.value as List);
        }

        userOrders.add(newOrderKey);
        await userOrderRef.set(userOrders);
      } catch (error) {
        print('Error adding order to user: $error');
      }

      // Group items by furniture ID
      final Map<String, dynamic> groupedItems = {};
      for (final item in items) {
        final String itemId = item['id'].toString();
        final String variantId = item['variantId'].toString();
        final int quantity = int.parse(item['quantity'].toString());
        final double price = double.parse(item['price'].toString());

        if (!groupedItems.containsKey(itemId)) {
          groupedItems[itemId] = {
            'selected_variants': [variantId],
            'quantity': quantity,
            'price': price * quantity,
            'discount': item['discount'] != null ? double.parse(item['discount'].toString()) : 0
          };
        } else {
          groupedItems[itemId]['selected_variants'].add(variantId);
          groupedItems[itemId]['quantity'] += quantity;
          groupedItems[itemId]['price'] += price * quantity;
        }
      }

      // Store order details in furniture/orders and deduct inventory
      try {
        for (final String itemId in groupedItems.keys) {
          final Map<String, dynamic> item = groupedItems[itemId];
          final DatabaseReference furnitureOrderRef = _dbRef.child('furniture/$itemId/orders');
          final DataSnapshot furnitureOrderSnapshot = await furnitureOrderRef.get();
          List<dynamic> furnitureOrders = [];

          if (furnitureOrderSnapshot.exists) {
            furnitureOrders = List<dynamic>.from(furnitureOrderSnapshot.value as List);
          }

          furnitureOrders.add({
            'order_id': newOrderId,
            'created_on': DateTime.now().toIso8601String(),
            'customer_id': userId,
            'discount': item['discount'],
            'quantity': item['quantity'],
            'selected_variants': item['selected_variants'],
            'price': item['price']
          });

          await furnitureOrderRef.set(furnitureOrders);

          // Deduct from the inventory of the furniture based on the variantId
          for (final String variantId in item['selected_variants']) {
            final DatabaseReference inventoryRef = _dbRef.child('furniture/$itemId/variants/$variantId/inventory');
            final DataSnapshot inventorySnapshot = await inventoryRef.get();

            if (inventorySnapshot.exists) {
              // Log the inventory value and type
              print("Inventory before parsing: ${inventorySnapshot.value} (${inventorySnapshot.value.runtimeType})");

              // Ensure the inventory is treated as an int
              int currentInventory = 0;

              if (inventorySnapshot.value != null) {
                if (inventorySnapshot.value is int) {
                  currentInventory = inventorySnapshot.value as int;
                } else if (inventorySnapshot.value is String) {
                  currentInventory = int.tryParse(inventorySnapshot.value as String) ?? 0;
                } else {
                  throw Exception('Unsupported type for inventory value: ${inventorySnapshot.value.runtimeType}');
                }
              }

              // Log the quantity value and type
              print("Quantity before parsing: ${item['quantity']} (${item['quantity'].runtimeType})");

              // Ensure the quantity is treated as an int
              int itemQuantity = 0;

              if (item['quantity'] != null) {
                if (item['quantity'] is int) {
                  itemQuantity = item['quantity'] as int;
                } else if (item['quantity'] is String) {
                  itemQuantity = int.tryParse(item['quantity'] as String) ?? 0;
                } else {
                  throw Exception('Unsupported type for quantity value: ${item['quantity'].runtimeType}');
                }
              }

              final int newInventory = currentInventory - itemQuantity;
              print("New inventory: $newInventory");

              await inventoryRef.set(newInventory);
            }
          }
        }
      } catch (error) {
        print('Error adding order to furniture or updating inventory: $error');
      }

      // Clear user cart
      try {
        final DatabaseReference userCartRef = _dbRef.child('users/$userId/cart');
        await userCartRef.set(null);
      } catch (error) {
        print('Error clearing cart: $error');
      }

      return {'success': true};
    } catch (error) {
      throw Exception('Failed to place order: $error');
    }
  }

  Future<void> addReview(String orderId, String itemId, int rating, String review) async {
    try {
      // Reference to the order
      DatabaseReference orderRef = _dbRef.child('orders/$orderId');
      DataSnapshot orderSnapshot = await orderRef.get();
      Map<dynamic, dynamic>? orderData = orderSnapshot.value as Map<dynamic, dynamic>?;

      // Check if order exists
      if (orderData == null) {
        throw Exception("Order not found");
      }

      // Extract the items list from the order
      List<dynamic> items = orderData['items'] ?? [];
      Map<dynamic, dynamic>? item = items.firstWhere((element) => element['id'] == itemId, orElse: () => null);

      // Check if item exists in the order
      if (item == null) {
        throw Exception("Item not found in order");
      }

      // Mark the item as reviewed
      item['reviewed'] = true;

      // Fetch the user information
      DatabaseReference userRef = _dbRef.child('users/${orderData['user_id']}');
      DataSnapshot userSnapshot = await userRef.get();
      Map<dynamic, dynamic>? userData = userSnapshot.value as Map<dynamic, dynamic>?;

      // Check if user data exists
      if (userData == null) {
        throw Exception("User not found");
      }

      // Create the review object
      item['review'] = {
        'user': {
          'id': orderData['user_id'],
          'name': userData['name'],
          'profile_picture': userData['profile_picture'] ?? ''
        },
        'rating': rating,
        'review': review,
        'created_on': DateTime.now().toIso8601String(), // ISO format
      };

      // Update the order with the modified item review
      await orderRef.update({
        'items': items
      });

      // Reference to the furniture reviews and create a new review entry
      DatabaseReference reviewRef = _dbRef.child('furniture/$itemId/reviews');
      DatabaseReference newReviewRef = reviewRef.push();

      await newReviewRef.set({
        'order_id': orderId,
        'user': {
          'id': orderData['user_id'],
          'name': userData['name'],
          'profile_picture': userData['profile_picture'] ?? ''
        },
        'rating': rating,
        'review': review,
        'created_on': DateTime.now().toIso8601String(), // ISO format
      });

      // Add the review reference to the user's reviews
      DatabaseReference userReviewRef = _dbRef.child('users/${orderData['user_id']}/reviews');
      DataSnapshot userReviewSnapshot = await userReviewRef.get();

      List<dynamic> userReviews = [];
      if (userReviewSnapshot.exists) {
        userReviews = List<dynamic>.from(userReviewSnapshot.value as List<dynamic>);
      }

      userReviews.add(newReviewRef.key);

      // Update the user's reviews
      await userReviewRef.set(userReviews);

    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }
}