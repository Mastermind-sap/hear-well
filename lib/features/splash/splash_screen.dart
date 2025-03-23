import 'package:echo_aid/core/utils/services/authentication/auth_service.dart';
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
    Future.delayed(const Duration(seconds: 2) , () {
      if(_authService.silentLogin()) {
        Navigator.pushNamedAndRemoveUntil(context, '/connection', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircleAvatar(
          radius: 50,
          child: FlutterLogo(size: 50,),
        )
      ),
    );
  }
}