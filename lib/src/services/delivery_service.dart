import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class DeliveryService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> updateStatus(String orderId, String status) async {
    // Get the current time in ISO 8601 format
    String currentTime = DateTime.now().toIso8601String();

    // Update the appropriate status field with the current time
    await _dbRef.child('orders/$orderId/completion_status').update({
      status: currentTime,
    });
  }

  Future<Map<String, dynamic>> reportDelivery(Map<String, dynamic> reportData) async {
    final String orderID = reportData['orderID'];
    final String description = reportData['description'];
    final List<Map<String, dynamic>> reportedItems = reportData['reportedItems'];

    try {
      await updateStatus(orderID, "OnHold");

      // Create a new report in the 'reports' node
      final reportsRef = _dbRef.child('reports');
      final newReportRef = reportsRef.push();
      await newReportRef.set({
        'order_id': orderID,
        'description': description,
        'items': reportedItems,
        'created_on': DateTime.now().toIso8601String(),
      });

      return {'success': true};
    } catch (error) {
      print('Error reporting delivery: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  Future<void> uploadProofOfDelivery(String orderId, List<File> images) async {
    List<String> downloadUrls = [];

    try {
      // Iterate over the images and upload them one by one
      for (int i = 0; i < images.length; i++) {
        // Create a reference to the storage path
        String filePath = 'orders/$orderId/proof_of_delivery/image_$i.jpg';
        Reference storageRef = _storage.ref().child(filePath);

        // Upload the file to Firebase Storage
        UploadTask uploadTask = storageRef.putFile(images[i]);
        TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

        // Get the download URL
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      // Store the download URLs in Firebase Realtime Database
      await _dbRef.child('orders/$orderId/proof_of_delivery').set(downloadUrls);

      print('Proof of Delivery uploaded successfully.');
    } catch (e) {
      print('Error uploading Proof of Delivery: $e');
      rethrow; // Rethrow the exception to handle it elsewhere if needed
    }
  }
}
