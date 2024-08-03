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
        final itemId = item['id'].toString();
        final variantId = item['variantId'].toString();
        final quantity = int.parse(item['quantity'].toString());
        final price = double.parse(item['price'].toString());

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

      // Store order details in furniture/orders
      try {
        for (final itemId in groupedItems.keys) {
          final item = groupedItems[itemId];
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
        }
      } catch (error) {
        print('Error adding order to furniture: $error');
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
}