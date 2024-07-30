import 'package:firebase_database/firebase_database.dart';

class CheckoutService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> placeOrder(Map<String, dynamic> data) async {
    final orderRef = _db.child('orders');
    final newOrderRef = orderRef.push();
    final orderId = newOrderRef.key;

    final userId = data['user'];
    final items = data['items'];
    final address = data['address'];
    final payment = data['payment'];
    final paymentMethod = data['payment_method'];
    final subtotal = data['subtotal'];
    final shipping = data['shipping'];
    final weight = data['weight'];
    final discount = data['discount'];
    final voucher = data['voucher'];
    final total = data['total'];
    final shippingDate = data['shipping_date'];
    final shippingTime = data['shipping_time'];

    try {
      if (voucher != null) {
        try {
          final voucherRef = _db.child('vouchers/${voucher['id']}/orders');
          final voucherSnapshot = await voucherRef.once();
          List<dynamic> currentOrders = [];
          if (voucherSnapshot.snapshot.value != null) {
            currentOrders = List<dynamic>.from(voucherSnapshot.snapshot.value as List);
          }
          currentOrders.add(orderId);
          await voucherRef.set(currentOrders);

          final userVoucherRef = _db.child('users/$userId/vouchers/${voucher['id']}');
          await userVoucherRef.set(false);

          final voucherUserRef = _db.child('vouchers/${voucher['id']}/users/$userId');
          await voucherUserRef.set(false);
        } catch (error) {
          print("Error adding order to voucher: $error");
        }
      }

      try {
        final userOrderRef = _db.child('users/$userId/orders');
        final userOrderSnapshot = await userOrderRef.once();
        List<dynamic> userOrders = [];
        if (userOrderSnapshot.snapshot.value != null) {
          userOrders = List<dynamic>.from(userOrderSnapshot.snapshot.value as List);
        }
        userOrders.add(orderId);
        await userOrderRef.set(userOrders);
      } catch (error) {
        print("Error adding order to user: $error");
      }

      final groupedItems = items.fold<Map<String, dynamic>>({}, (acc, item) {
        if (!acc.containsKey(item['id'])) {
          acc[item['id']] = {
            'selected_variants': [item['variantId']],
            'quantity': item['quantity'],
            'price': item['price'] * item['quantity'],
          };
        } else {
          acc[item['id']]['selected_variants'].add(item['variantId']);
          acc[item['id']]['quantity'] += item['quantity'];
          acc[item['id']]['price'] += item['price'] * item['quantity'];
        }
        return acc;
      });

      for (var itemId in groupedItems.keys) {
        final item = groupedItems[itemId];
        try {
          final furnitureOrderRef = _db.child('furniture/$itemId/orders');
          final furnitureOrderSnapshot = await furnitureOrderRef.once();
          List<dynamic> furnitureOrders = [];
          if (furnitureOrderSnapshot.snapshot.value != null) {
            furnitureOrders = List<dynamic>.from(furnitureOrderSnapshot.snapshot.value as List);
          }
          furnitureOrders.add({
            'order_id': orderId,
            'created_on': DateTime.now().toIso8601String(),
            'customer_id': userId,
            'discount': item['discount'],
            'quantity': item['quantity'],
            'selected_variants': item['selected_variants'],
            'price': item['price'],
          });
          await furnitureOrderRef.set(furnitureOrders);
        } catch (error) {
          print("Error adding order to furniture: $error");
        }
      }

      try {
        final userCartRef = _db.child('users/$userId/cart');
        await userCartRef.set(null);
      } catch (error) {
        print("Error clearing cart: $error");
      }

      await newOrderRef.set({
        'order_id': orderId,
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
        'completion_status': 'Pending',
        'arrival_status': 'Pending',
        'created_on': DateTime.now().toIso8601String(),
      });

      return;
    } catch (error) {
      throw Exception('Failed to place order: $error');
    }
  }
}