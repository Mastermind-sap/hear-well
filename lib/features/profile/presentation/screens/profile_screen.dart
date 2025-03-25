import 'package:hear_well/core/theme/app_gradients.dart';
import 'package:hear_well/core/theme/app_theme.dart';
import 'package:hear_well/core/utils/services/authentication/auth_service.dart';
import 'package:hear_well/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// Add translation imports
import 'package:hear_well/core/localization/translation_helper.dart';

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

  // Add Bluetooth state variables
  bool _isBluetoothOn = false;
  String _connectedDeviceName = "";
  bool _isCheckingBluetooth = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _checkBluetoothStatus();
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
            username =
                currentUser.displayName ?? userData['username'] ?? "User";
            email = currentUser.email ?? userData['email'] ?? "";
            profileImageUrl =
                userData['profileImageUrl'] ?? currentUser.photoURL ?? "";
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
        builder:
            (context) => EditProfileScreen(
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
      MaterialPageRoute(builder: (context) => BadgesScreen()),
    );
  }

  // Add method to check Bluetooth status
  Future<void> _checkBluetoothStatus() async {
    try {
      // Check if Bluetooth is on
      final isOn =
          await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;

      // Get connected devices
      List<BluetoothDevice> connectedDevices = [];
      if (isOn) {
        connectedDevices = await FlutterBluePlus.connectedDevices;
      }

      if (mounted) {
        setState(() {
          _isBluetoothOn = isOn;
          _isCheckingBluetooth = false;
          if (connectedDevices.isNotEmpty) {
            _connectedDeviceName =
                connectedDevices.first.name.isNotEmpty
                    ? connectedDevices.first.name
                    : "Unknown Device";
          }
        });
      }
    } catch (e) {
      print("Error checking Bluetooth status: $e");
      if (mounted) {
        setState(() {
          _isCheckingBluetooth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AuthService _auth = AuthService();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          context.tr('my_profile'), // Changed to use translation
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: AppGradients.appBarDecoration(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(
            Theme.of(context).brightness,
          ),
        ),
        child: SafeArea(
          child:
              isLoading
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
        ),
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

class ProfileContent extends StatelessWidget {
  final String profileImageUrl;
  final String username;
  final String email;
  final int maxUsageHours;
  final List<String> badges;
  final VoidCallback editProfile;
  final VoidCallback onBadgesTap;

  const ProfileContent({
    Key? key,
    required this.profileImageUrl,
    required this.username,
    required this.email,
    required this.maxUsageHours,
    required this.badges,
    required this.editProfile,
    required this.onBadgesTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with gradient
          GradientContainer(
            gradientColors: [
              colorScheme.primary.withOpacity(0.8),
              colorScheme.primary,
            ],
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                // Profile image with gradient border
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage:
                        profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                    child:
                        profileImageUrl.isEmpty
                            ? Icon(
                              Icons.person,
                              size: 40,
                              color: colorScheme.onPrimaryContainer,
                            )
                            : null,
                  ),
                ),
                const SizedBox(width: 20),

                // Profile info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: editProfile,
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(context.tr('edit_profile')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bluetooth connection status card (restored)
          _buildBluetoothStatusCard(context),

          const SizedBox(height: 24),

          // Usage stats section
          Text(
            context.tr("usage_statistics"),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Stats cards
          Row(
            children: [
              // Hours used card
              Expanded(
                child: GradientContainer(
                  gradientColors: [Colors.blue.shade500, Colors.blue.shade700],
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr("total_hours"),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "$maxUsageHours",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        context.tr("hours_enhanced_audio"),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Badges card
              Expanded(
                child: GradientContainer(
                  gradientColors: [
                    Colors.amber.shade500,
                    Colors.amber.shade700,
                  ],
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr("badges"),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "${badges.length}",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        context.tr("achievements_earned"),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Badges section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr("recent_badges"),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onBadgesTap,
                child: Text(
                  context.tr("view_all"),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Badges preview
          badges.isEmpty
              ? _buildNoBadgesView(context)
              : _buildBadgesPreview(context, badges),
        ],
      ),
    );
  }

  // Method to build Bluetooth status card
  Widget _buildBluetoothStatusCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBluetoothOn =
        false; // This is a placeholder - we'll fix this shortly
    final connectedDeviceName = ""; // Placeholder

    return StreamBuilder<BluetoothAdapterState>(
      stream: FlutterBluePlus.adapterState,
      initialData: BluetoothAdapterState.unknown,
      builder: (c, snapshot) {
        final state = snapshot.data;
        final isOn = state == BluetoothAdapterState.on;

        return FutureBuilder<List<BluetoothDevice>>(
          future:
              isOn
                  ? Future<List<BluetoothDevice>>.value(
                    FlutterBluePlus.connectedDevices,
                  )
                  : Future<List<BluetoothDevice>>.value([]),
          builder: (context, deviceSnapshot) {
            String deviceName = context.tr("no_devices_found");
            bool hasDevice = false;

            if (deviceSnapshot.hasData && deviceSnapshot.data!.isNotEmpty) {
              deviceName =
                  deviceSnapshot.data!.first.name.isNotEmpty
                      ? deviceSnapshot.data!.first.name
                      : "Unknown Device";
              hasDevice = true;
            }

            return GradientContainer(
              gradientColors:
                  isOn
                      ? [
                        colorScheme.secondary.withOpacity(0.7),
                        colorScheme.secondary,
                      ]
                      : [Colors.grey.shade500, Colors.grey.shade700],
              borderRadius: BorderRadius.circular(16),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOn
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr("bluetooth_status"),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              isOn
                                  ? context.tr("connected")
                                  : context.tr("disconnected"),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (hasDevice) ...[
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 6),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  deviceName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isOn) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoBadgesView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr("no_badges_earned"),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr("use_app_earn_badges"),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesPreview(BuildContext context, List<String> badges) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayBadges = badges.length > 3 ? badges.sublist(0, 3) : badges;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.surfaceGradient(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            displayBadges.map((badge) {
              final colors = [Colors.blue, Colors.purple, Colors.green];
              final icons = [
                Icons.star,
                Icons.military_tech,
                Icons.workspace_premium,
              ];
              final index = badges.indexOf(badge) % 3;

              return Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors[index].withOpacity(0.7), colors[index]],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors[index].withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icons[index], color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}
