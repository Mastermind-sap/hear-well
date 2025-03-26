import 'package:hear_well/core/utils/services/authentication/auth_service.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AuthService _authService = AuthService();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (_authService.silentLogin()) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/connection',
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double radius = MediaQuery.of(context).size.width * 0.25;
    return Scaffold(
      body: Center(
        child: CircleAvatar(
          radius: radius,
          child: Image.asset('assets/images/app_icon.png'),
        ),
      ),
    );
  }
}
