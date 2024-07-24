import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddressService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> addAddress(String userId, Map<String, dynamic> address) async {
    if (userId != null) {
      await _db.child('users/$userId/addresses').push().set(address);
    }
  }

  Future<void> updateAddress(String userId, String addressId, Map<String, dynamic> address) async {
    if (userId != null) {
      await _db.child('users/$userId/addresses').child(addressId).update(address);
    }
  }

  Future<void> removeAddress(String userId, String addressId) async {
    if (userId != null) {
      await _db.child('users/$userId/addresses').child(addressId).remove();
    }
  }

  Future<void> updateDefaultAddress(String userId, String addressId) async {
    if (userId != null) {
      final snapshot = await _db.child('users/$userId/addresses').get();
      if (snapshot.exists) {
        final addressesData = snapshot.value as Map<dynamic, dynamic>;
        addressesData.forEach((key, value) async {
          final address = value as Map<dynamic, dynamic>;
          final isDefault = key == addressId;
          await _db.child('users/$userId/addresses').child(key).update({
            'isDefault': isDefault,
          });
        });
      }
    }
  }
}