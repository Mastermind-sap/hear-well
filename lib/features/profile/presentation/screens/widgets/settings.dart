import 'package:echo_aid/core/utils/services/authentication/auth_service.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AuthService _authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListTile(
        title: const Text('Logout'),
        onTap: () {
          _authService.logout();
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        },
        )
    );
  }
}