import 'dart:typed_data';

import 'package:echo_aid/core/utils/extensions/list_extension.dart';
import 'package:echo_aid/core/utils/services/authentication/auth_service.dart';
import 'package:echo_aid/core/utils/services/validation/validation.dart';
import 'package:echo_aid/core/utils/widgets/profile_image_viewer.dart';
import 'package:echo_aid/features/auth/signup/widgets/gradient_button.dart';
import 'package:echo_aid/features/auth/signup/widgets/login_navigation_link.dart';
import 'package:echo_aid/features/auth/signup/widgets/signup_input_field.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Size size = MediaQuery.of(context).size;
    double height = size.height;
    double fieldGap = height * 0.015;
    double smallGap = height * 0.025;
    final AuthService _authService = AuthService();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.colorScheme.surface,
                  Color(0xFF252525),
                ]
              : [
                  theme.colorScheme.surface,
                  Color(0xFFF0F0F0),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: isDark ? 1 : 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient Text Header
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: isDark
                  ? [theme.colorScheme.primary, theme.colorScheme.secondary]
                  : [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              "Create Account",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: isDark
                  ? [Colors.grey.shade400, Colors.grey.shade300]
                  : [Colors.grey.shade700, Colors.grey.shade600],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              "Sign up to get started",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          SizedBox(height: smallGap),
          
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    width: size.width,
                    alignment: Alignment.center,
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
                ),
                SizedBox(height: smallGap),
                
                SignUpInputField(
                  controller: _usernameController,
                  label: "Username",
                  icon: Icons.person,
                  validator: (value) => Validator.validateUsername(value!),
                ),
                
                SignUpInputField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email,
                  isPassword: false,
                  validator: (value) => Validator.validateEmail(value!),
                ),
                
                SignUpInputField(
                  controller: _passController,
                  label: "Password",
                  icon: Icons.lock,
                  validator: (value) => Validator.validatePassword(value!),
                  obscureText: hidePassword,
                  isPassword: true,
                ),
                
                SizedBox(height: smallGap),
                
                GradientButton(
                  text: "SIGN UP",
                  isLoading: _isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
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
                          Navigator.pushNamedAndRemoveUntil(context, '/connection', (route) => false);
                        }
                      }
                    }
                  },
                ),
              ].separate(fieldGap),
            ),
          ),
          
          SizedBox(height: smallGap * 1.5),
          
          LoginNavigationLink(),
        ],
      ),
    );
  }
}