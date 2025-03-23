import 'package:echo_aid/core/theme/app_gradients.dart';
import 'package:echo_aid/core/theme/app_theme.dart';
import 'package:echo_aid/core/utils/extensions/list_extension.dart';
import 'package:echo_aid/core/utils/services/authentication/auth_service.dart';
import 'package:echo_aid/features/auth/login/widgets/login_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Add translation imports
import 'package:echo_aid/core/localization/translation_helper.dart';

class LoginPage extends StatefulWidget {
  //route
  static const String routeName = "/LoginPage";

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
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
    double width = size.width;
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo/Avatar with gradient border
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors:
                              isDark
                                  ? [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ]
                                  : [
                                    theme.colorScheme.primary.withOpacity(0.8),
                                    theme.colorScheme.secondary.withOpacity(
                                      0.8,
                                    ),
                                  ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor:
                            isDark
                                ? theme.colorScheme.surface
                                : theme.colorScheme.background,
                        radius: width * 0.15,
                        child: Icon(
                          Icons.headphones,
                          size: 80,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),

                    // App name with gradient text
                    const SizedBox(height: 20),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback:
                          (bounds) => LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                      child: Text(
                        context.tr('app_name'),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      context.tr('app_subtitle'),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),

                    // Login form with gradient border
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 30,
                      ),
                      child: LoginForm(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
