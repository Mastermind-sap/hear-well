import 'package:echo_aid/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String username = "";
  String email = "";
  String profileImageUrl = "";
  int maxUsageHours = 0;
  List<String> badges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot userDoc = 
            await _firestore.collection('users').doc(currentUser.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            username = currentUser.displayName ?? userData['username'] ?? "User";
            email = currentUser.email ?? userData['email'] ?? "";
            profileImageUrl = userData['profileImageUrl'] ?? currentUser.photoURL ?? "";
            maxUsageHours = userData['maxUsageHours'] ?? 0;
            badges = List<String>.from(userData['badges'] ?? []);
            isLoading = false;
          });
        } else {
          await _createUserDocument(currentUser);
          
          setState(() {
            username = currentUser.displayName ?? "User";
            email = currentUser.email ?? "";
            profileImageUrl = currentUser.photoURL ?? "";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> _createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'username': user.displayName,
        'profileImageUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'badges': [],
        'maxUsageHours': 0,
      });
    } catch (e) {
      print("Error creating user document: $e");
    }
  }

  void _editProfile() async {
    // This method will be called when the Edit button is pressed
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentUsername: username,
          currentEmail: email,
          currentImageUrl: profileImageUrl,
        ),
      ),
    );
    
    // If we returned with updated data, refresh the profile
    if (result == true) {
      _fetchUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("My Profile", 
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          )
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined),
            onPressed: () {},
            tooltip: 'Settings',
          ),
        ],
      ),
      body: isLoading 
        ? _buildLoadingState()
        : ProfileContent(profileImageUrl: profileImageUrl, username: username, email: email, maxUsageHours: maxUsageHours, badges: badges, editProfile: _editProfile),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[800]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }



  
}