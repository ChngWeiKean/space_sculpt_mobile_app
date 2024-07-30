import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class CartService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> addToCart(String userId,String furnitureId, String variantId) async {
    if (userId != null) {
      await _db.child('users/$userId/cart').push().set({
        'furnitureId': furnitureId,
        'variantId': variantId,
        'quantity': 1,
        'created_on' : DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.child('users/${user.uid}/cart').child(cartItemId).remove();
    }
  }

  Future<void> updateCartQuantity(String cartItemId, int quantity) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.child('users/${user.uid}/cart').child(cartItemId).update({
        'quantity': quantity,
      });
    }
  }
}
