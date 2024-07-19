import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserProfileService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> editCustomerProfile(Map<String, dynamic> userData, File? profilePictureFile) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (profilePictureFile != null) {
        // Store the profile picture in Firebase Storage and get the download URL
        String downloadUrl = await _storeProfilePicture(user.uid, profilePictureFile);
        userData['profile_picture'] = downloadUrl;
      }

      // Update the user data in Firebase Realtime Database
      await _db.child('users/${user.uid}').update(userData);
    }
  }

  Future<String> _storeProfilePicture(String uid, File profilePictureFile) async {
    // Reference to the file location in Firebase Storage
    Reference storageRef = _storage.ref().child('users').child(uid);

    // Upload the file
    await storageRef.putFile(profilePictureFile);

    // Get the download URL
    String downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl;
  }
}