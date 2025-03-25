import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:hear_well/core/theme/app_theme.dart';
import 'package:hear_well/core/utils/controllers/image_controller.dart';
import 'package:hear_well/core/utils/services/authentication/auth_service.dart';
import 'package:hear_well/features/profile/presentation/screens/widgets/gradient_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// Add translation imports
import 'package:hear_well/core/localization/translation_helper.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentUsername;
  final String currentEmail;
  final String currentImageUrl;

  const EditProfileScreen({
    Key? key,
    required this.currentUsername,
    required this.currentEmail,
    required this.currentImageUrl,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
    _emailController = TextEditingController(text: widget.currentEmail);

    // Listen for changes in the text fields
    _usernameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Check if any changes have been made
  void _checkForChanges() {
    setState(() {
      _hasChanges =
          _usernameController.text != widget.currentUsername ||
          _emailController.text != widget.currentEmail ||
          _selectedImageFile != null;
    });
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _hasChanges = true;
      });

      // Read file as bytes for uploading
      _selectedImageBytes = await pickedFile.readAsBytes();
    }
  }

  // Save profile changes
  Future<void> _saveChanges() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showError(context.tr("failed_update"));
        return;
      }

      // Update display name if changed
      if (_usernameController.text != widget.currentUsername) {
        await currentUser.updateDisplayName(_usernameController.text);
      }

      // Update profile image if selected
      if (_selectedImageBytes != null) {
        final String? imageUrl = await ImageController.uploadProfileImage(
          _selectedImageBytes!,
          currentUser.uid,
        );

        if (imageUrl != null && imageUrl.isNotEmpty) {
          // Update the image URL in Auth and Firestore
          await _authService.updateProfileImage(currentUser.uid, imageUrl);
        }
      }

      // Return to profile screen with success
      Navigator.pop(context, true);
      _showSuccess(context.tr("update_successful"));
    } catch (e) {
      _showError("${context.tr('failed_update')}: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Color(0xFFF5F5F5);
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr("edit_profile"),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        // Remove the save button from the app bar
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    // Profile image
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(3),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child:
                            _selectedImageFile != null
                                ? Image.file(
                                  _selectedImageFile!,
                                  fit: BoxFit.cover,
                                )
                                : widget.currentImageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                  imageUrl: widget.currentImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        color: Colors.grey[800],
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        color: Colors.grey[800],
                                        child: Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                )
                                : Container(
                                  color: Colors.grey[800],
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    // Edit icon
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: backgroundColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Username Field
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: context.tr("username"),
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    filled: true,
                    fillColor: cardColor,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Email Field (read-only)
              Container(
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: textColor),
                  enabled: false, // Read-only
                  decoration: InputDecoration(
                    labelText: context.tr("email"),
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    fillColor:
                        isDarkMode
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                    filled: true,
                    prefixIcon: Icon(Icons.email, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Information card
              GradientContainer(
                gradientColors:
                    isDarkMode
                        ? [Colors.grey.shade900, Colors.grey.shade800]
                        : [Colors.blue.shade50, Colors.blue.shade100],
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr("update_profile"),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            context.tr("email_not_changeable"),
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Only keep the bottom save button when changes are made
              if (_hasChanges)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _saveChanges,
                      icon:
                          _isUploading
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Icon(Icons.save),
                      label: Text(
                        context.tr("update_profile"),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
