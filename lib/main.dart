import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:echo_aid/core/theme/app_theme.dart';

import 'features/features.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final micStatus = await Permission.microphone.request();
  final btStatus = await Permission.bluetooth.request();
  if (micStatus.isGranted && btStatus.isGranted) {
    runApp(const MyApp());
  } else {
    runApp(const _PermissionDeniedApp());
  }
}

class _PermissionDeniedApp extends StatelessWidget {
  const _PermissionDeniedApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: _DeniedScreen()));
  }
}

class _DeniedScreen extends StatefulWidget {
  @override
  State<_DeniedScreen> createState() => _DeniedScreenState();
}

class _DeniedScreenState extends State<_DeniedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissions denied. Please enable them in Settings.'),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        SystemNavigator.pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Exiting...'));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo Aid',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: "/",
      routes: {
        "/": (context) => const Application(),
        "/home": (context) => const HomeScreen(),
        "/profile": (context) => const ProfileScreen(),
        "/setting": (context) => const SettingScreen(),
      },
    );
  }
}
