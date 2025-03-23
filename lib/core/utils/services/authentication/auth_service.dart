import 'dart:typed_data';

import 'package:echo_aid/core/utils/controllers/image_controller.dart';
import 'package:echo_aid/core/utils/widgets/profile_image_viewer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signup(
    String email,
    String password,
    String username,
    GlobalKey<ProfileImageViewerState> key,
    Uint8List? profileImage,
  ) async {
    try {
      debugPrint('Starting user signup process');

      // Create the user account
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Get the user
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception("Failed to create user account");
      }

      debugPrint('User created with UID: ${user.uid}');

      // Update display name
      await user.updateDisplayName(username);
      debugPrint('Display name updated to: $username');

      // Create a Firestore document for the user
      final userDoc = _firestore.collection('users').doc(user.uid);

      // Initialize user data
      Map<String, dynamic> userData = {
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'badges': [],
        'maxUsageHours': 0,
      };

      // Handle profile image upload
      String? imageUrl;
      if (profileImage != null) {
        try {
          debugPrint('Profile image available for upload');

          // Make sure the state is accessible
          if (key.currentState == null) {
            debugPrint(
              'ProfileImageViewerState is null - cannot access upload method',
            );
            // Fall back to direct upload
            imageUrl = await ImageController.uploadProfileImage(
              profileImage,
              user.uid,
            );

            if (imageUrl != null && imageUrl.isNotEmpty) {
              await user.updatePhotoURL(imageUrl);
              debugPrint('Uploaded image directly: $imageUrl');
            }
          } else {
            // Upload via the widget's state
            imageUrl = await key.currentState!.uploadSelectedImage(user.uid);

            // Update user profile with photo URL
            if (imageUrl != null && imageUrl.isNotEmpty) {
              await user.updatePhotoURL(imageUrl);
              debugPrint(
                'Successfully updated user profile with image: $imageUrl',
              );
            } else {
              debugPrint('Failed to get valid image URL after upload');
            }
          }

          // Store image URL in Firestore if available
          if (imageUrl != null && imageUrl.isNotEmpty) {
            userData['profileImageUrl'] = imageUrl;
          }
        } catch (imageError) {
          // Don't let image upload failure prevent account creation
          debugPrint('Error uploading profile image: $imageError');
        }
      } else {
        debugPrint('No profile image provided during signup');
      }

      // Save user data to Firestore
      await userDoc.set(userData);
      debugPrint('User data saved to Firestore');

      debugPrint('Signup process completed successfully');
    } catch (e) {
      debugPrint('Error during signup: $e');
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final String _email = email;
      final String _password = password;
      await _auth
          .signInWithEmailAndPassword(email: _email, password: _password)
          .then((value) {
            print("User logged in");
          })
          .onError((error, stackTrace) {
            print("User not found");
          });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  bool silentLogin() {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Check if a user is currently logged in
  bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  // Method to update profile image URL in both Auth and Firestore
  Future<bool> updateProfileImage(String userId, String imageUrl) async {
    try {
      // Update in Firebase Auth
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePhotoURL(imageUrl);
      }

      // Update in Firestore
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
      });

      return true;
    } catch (e) {
      debugPrint('Error updating profile image URL: $e');
      return false;
    }
  }

  // Get current user data from Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user data: $e');
      return null;
    }
  }
}
