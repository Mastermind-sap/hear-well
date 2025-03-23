import 'package:echo_aid/core/theme/app_theme.dart';
import 'package:echo_aid/core/utils/extensions/list_extension.dart';
import 'package:echo_aid/core/utils/services/authentication/auth_service.dart';
import 'package:echo_aid/features/auth/login/widgets/login_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  //route
  static const String routeName = "/LoginPage";

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  
  void _silentLogin() {
    if(_authService.silentLogin()) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }
  
  @override
  void initState() {
    super.initState();
    // _silentLogin();
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
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                          ? [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ]
                          : [
                              theme.colorScheme.primary.withOpacity(0.8),
                              theme.colorScheme.secondary.withOpacity(0.8),
                            ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: isDark 
                        ? theme.colorScheme.surface 
                        : theme.colorScheme.background,
                      radius: width * 0.15,
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ),
                  
                  // Login form with gradient border
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: LoginForm(),
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