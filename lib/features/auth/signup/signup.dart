import 'package:echo_aid/core/utils/extensions/list_extension.dart';
import 'package:echo_aid/features/auth/signup/widgets/signup_form.dart';
import 'package:echo_aid/features/auth/signup/widgets/signup_header.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  SignUpFormState loginFormState = SignUpFormState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Size size = MediaQuery.of(context).size;
    double height = size.height;
    double gap = height * 0.04;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [
                  Colors.black,
                  Color(0xFF121212),
                  Color(0xFF262626),
                ] 
              : [
                  Color(0xFFF5F5F5),
                  Color(0xFFE0E0E0),
                  Color(0xFFEEEEEE),
                ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo/Avatar with gradient border
                  const SignupHeader(),
                  
                  // Signup form with padding
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: SignUpForm(),
                  ),
                ].separate(gap),
              ),
            ),
          ),
        ),
      ),
    );
  }
}