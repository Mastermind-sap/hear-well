import 'package:echo_aid/core/theme/app_theme.dart';
import 'package:echo_aid/core/utils/services/authentication/auth_service.dart';
import 'package:echo_aid/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

import 'widgets/widgets.dart';
import 'badges_screen.dart';

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
      debugPrint("Error fetching user data: $e");
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
      debugPrint("Error creating user document: $e");
    }
  }

  void _editProfile() async {
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
    
    if (result == true) {
      _fetchUserData();
    }
  }

  void _navigateToBadges() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => BadgesScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    AuthService _auth = AuthService();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Color(0xFFF5F5F5);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "My Profile", 
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          )
        ),
        // backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
            onPressed: () {
              _auth.logout();
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: isLoading 
        ? _buildLoadingState()
        : ProfileContent(
            profileImageUrl: profileImageUrl, 
            username: username, 
            email: email, 
            maxUsageHours: maxUsageHours, 
            badges: badges, 
            editProfile: _editProfile,
            onBadgesTap: _navigateToBadges,
          ),
    );
  }

  Widget _buildLoadingState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[300]!,
        highlightColor: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card shimmer
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            SizedBox(height: 24),
            
            // Title shimmer
            Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 16),
            
            // Stats cards shimmer
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Another title shimmer
            Container(
              width: 80,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 16),
            
            // Badge section shimmer
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}