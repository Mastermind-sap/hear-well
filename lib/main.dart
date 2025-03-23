import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:echo_aid/core/theme/app_theme.dart';
import 'package:echo_aid/services/audio_service.dart';

import 'features/features.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Request necessary permissions for background audio
  await _requestPermissions();

  // Initialize audio service
  // final audioService = AudioService();
  // await audioService.initialize();

  runApp(MyApp());
}

Future<void> _requestPermissions() async {
  final micStatus = await Permission.microphone.request();
  final bluetoothStatus = await Permission.bluetooth.request();
  await Permission.notification.request();
  await Permission.ignoreBatteryOptimizations.request();

  if (micStatus.isDenied || bluetoothStatus.isDenied) {
    runApp(const _PermissionDeniedApp());
  }
}

// Permission denied fallback remains the same
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
      initialRoute: "/splash",
      routes: {
        "/": (context) => const Application(),
        "/login": (context) => const LoginPage(),
        "/signup": (context) => const SignupScreen(),
        "/home": (context) => const HomeScreen(),
        "/profile": (context) => ProfileScreen(),
        "/setting": (context) => const SettingScreen(),
        "/connection": (context) => ConnectionScreen(),
        "/splash": (context) => const SplashScreen(),
      },
    );
  }
}
