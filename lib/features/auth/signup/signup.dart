import 'package:echo_aid/core/theme/app_gradients.dart';
import 'package:echo_aid/core/utils/extensions/list_extension.dart';
import 'package:echo_aid/features/auth/signup/widgets/signup_form.dart';
import 'package:echo_aid/features/auth/signup/widgets/signup_header.dart';
import 'package:flutter/material.dart';
// Add translation imports
import 'package:echo_aid/core/localization/translation_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  SignUpFormState loginFormState = SignUpFormState();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
          gradient: AppGradients.backgroundGradient(theme.brightness),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Signup form with padding
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: SignUpForm(),
                    ),
                  ].separate(gap * 0.5), // Reduced the gap for better spacing
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
