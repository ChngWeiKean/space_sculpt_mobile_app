import 'package:firebase_database/firebase_database.dart';

class VoucherService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> redeemVoucher(String userId, String voucherId) async {
    if (userId != null) {
      // Check if voucher already redeemed
      final snapshot = await _db.child('users/$userId/vouchers/$voucherId').get();
      if (snapshot.exists) {
        final isRedeemed = snapshot.value as bool;
        if (isRedeemed) {
          throw Exception('Voucher already redeemed.');
        }
      }

      // Check if voucher exists in vouchers
      final voucherSnapshot = await _db.child('vouchers/$voucherId').get();
      if (!voucherSnapshot.exists) {
        throw Exception('Voucher not found.');
      }

      await _db.child('users/$userId/vouchers').update({
        voucherId: true,
      });
    }
  }
}