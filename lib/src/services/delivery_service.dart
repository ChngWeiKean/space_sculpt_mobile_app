import 'package:firebase_database/firebase_database.dart';

class DeliveryService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> updateStatus(String orderId, String status) async {
    // Get the current time in ISO 8601 format
    String currentTime = DateTime.now().toIso8601String();

    // Update the appropriate status field with the current time
    await _dbRef.child('orders/$orderId/completion_status').update({
      status: currentTime,
    });
  }
}
