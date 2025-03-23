import 'package:flutter/material.dart';

class LoginNavigationLink extends StatelessWidget {
  const LoginNavigationLink({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return TextButton(
      onPressed: () {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      },
      child: RichText(
        text: TextSpan(
          text: "Already have an account? ",
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700], 
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: "Login",
              style: TextStyle(
                color: isDarkMode ? Colors.cyan[300] : Colors.cyan[700],
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
