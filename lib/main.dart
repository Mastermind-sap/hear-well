import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:echo_aid/core/theme/app_theme.dart';
import 'package:echo_aid/services/audio_service.dart';
// Add imports for localization
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:echo_aid/core/localization/app_localizations.dart';
import 'package:echo_aid/core/localization/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  runApp(
    // Wrap app with Provider for language management
    ChangeNotifierProvider(create: (_) => LanguageProvider(), child: MyApp()),
  );
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Static reference to access the state from anywhere
  static MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  // Method to update theme mode
  void updateThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Get the current language from the provider
    final languageProvider = Provider.of<LanguageProvider>(context);

    // Get the supported locales with a fallback to ensure it's never empty
    final List<Locale> supportedLocales =
        languageProvider.availableLanguages.keys
            .map((languageCode) => Locale(languageCode))
            .toList();

    // Fallback if somehow the list is empty
    if (supportedLocales.isEmpty) {
      supportedLocales.add(const Locale('en'));
    }

    return MaterialApp(
      title: 'Echo Aid',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,

      // Configure localization with the safety check
      locale: languageProvider.currentLocale,
      supportedLocales: supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

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
