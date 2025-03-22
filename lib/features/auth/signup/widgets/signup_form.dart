import 'dart:typed_data';

import 'package:echo_aid/core/utils/extensions/list_extension.dart';
import 'package:echo_aid/core/utils/services/authentication/auth_service.dart';
import 'package:echo_aid/core/utils/services/validation/validation.dart';
// import 'package:echo_aid/core/utils/widgets/custom_text_field.dart';
import 'package:echo_aid/core/utils/widgets/profile_image_viewer.dart';
import 'package:flutter/material.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => SignUpFormState();
}

class SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _profileImageKey = GlobalKey<ProfileImageViewerState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool hidePassword = true;
  IconData passVisibility = Icons.visibility;
  Uint8List? _profileImage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    //screen height and width
    Size size = MediaQuery.of(context).size;
    double width = size.width;
    double height = size.height;
    //size constants
    double fieldGap = height * 0.012;
    double smallGap = height * 0.015;
    double formWidth = width * 0.85;
    double fieldHeight = height * 0.075 + 8;
    final AuthService _authService = AuthService();
    
    return Container(
      width: formWidth,
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
                  colors: [Colors.grey.shade900, Colors.grey.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Text(
            "Create Account",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[200],
            ),
          ),
          Text(
            "Sign up to get started",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: smallGap),
          
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ProfileImageViewer(
                    key: _profileImageKey,
                    height: height * 0.15,
                    uploadImmediately: false,
                    onImageChange: (image) {
                      setState(() {
                        _profileImage = image;
                      });
                    }
                  ),
                ),
                SizedBox(height: smallGap),
                
                TextFormField(
                controller: _usernameController,
                style: TextStyle(color: Colors.white),
                validator: (value) => Validator.validateUsername(value!),
                decoration: InputDecoration(
                  labelText: "Username",
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  fillColor: Colors.grey.shade900,
                  filled: true,
                  prefixIcon: Icon(Icons.person, color: Colors.grey),
                ),
              ),
                TextFormField(
                controller: _emailController,
                style: TextStyle(color: Colors.white),
                validator: (value) => Validator.validateEmail(value!),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  fillColor: Colors.grey.shade900,
                  filled: true,
                  prefixIcon: Icon(Icons.email, color: Colors.grey),
                ),
              ),
                TextFormField(
                  controller: _passController,
                style: TextStyle(color: Colors.white),
                validator: (value) => Validator.validatePassword(value!),
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  fillColor: Colors.grey.shade900,
                  filled: true,
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                        passVisibility = hidePassword ? Icons.visibility : Icons.visibility_off;
                      });
                    },
                    icon: Icon(
                      passVisibility,
                      color: Colors.grey[200],
                    ),
                  ),
                  
                ),
                
                  
                ),
                
                SizedBox(height: smallGap),
                
                Container(
                  width: double.infinity,
                  height: fieldHeight * 0.9,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      
                      try {
                        await _authService.signup(
                          _emailController.text,
                          _passController.text, 
                          _usernameController.text,
                          _profileImageKey,
                          _profileImage
                        );
                      } finally {
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.cyan],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "SIGN UP",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              ].separate(fieldGap),
            ),
          ),
          
          SizedBox(height: smallGap * 1.5),

          TextButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: RichText(
              text: TextSpan(
                text: "Already have an account? ",
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                children: [
                  TextSpan(
                    text: "Login",
                    style: TextStyle(
                      color: Colors.cyan[700],
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}