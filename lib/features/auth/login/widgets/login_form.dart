import 'package:echo_aid/core/utils/extensions/list_extension.dart';
import 'package:echo_aid/core/utils/services/authentication/auth_service.dart';
import 'package:echo_aid/features/auth/login/widgets/login_header.dart';
import 'package:echo_aid/features/auth/login/widgets/login_input_field.dart';
import 'package:echo_aid/features/auth/login/widgets/login_button.dart';
import 'package:echo_aid/features/auth/login/widgets/login_footer.dart';
import 'package:flutter/material.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool hidePassword = true;
  IconData passVisibility = Icons.visibility;
  bool _isLoading = false;

  void togglePasswordVisibility() {
    setState(() {
      hidePassword = !hidePassword;
      passVisibility = hidePassword ? Icons.visibility : Icons.visibility_off;
    });
  }

  void handleLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = AuthService();
        await authService.login(
          _emailController.text,
          _passController.text,
        );
        
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/connection',
            (route) => false,
          );
        }
      } catch (e) {
        // Handle login errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Size size = MediaQuery.of(context).size;
    double height = size.height;
    double fieldGap = height * 0.015;
    double smallGap = height * 0.025;

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
          const LoginHeader(),
          
          SizedBox(height: smallGap),
          
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoginInputField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email,
                  isPassword: false,
                ),
                
                LoginInputField(
                  controller: _passController,
                  label: "Password",
                  icon: Icons.lock,
                  isPassword: true,
                  obscureText: hidePassword,
                  suffixIcon: passVisibility,
                  onSuffixIconPressed: togglePasswordVisibility,
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    ),
                    child: Text(
                      "Forgot password?",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: smallGap * 0.8),
                
                LoginButton(
                  onPressed: _isLoading ? null : () => handleLogin(context),
                  isLoading: _isLoading,
                  label: "LOGIN",
                ),
              ].separate(fieldGap),
            ),
          ),
          
          SizedBox(height: smallGap),
          
          const LoginFooter(),
        ],
      ),
    );
  }
}
