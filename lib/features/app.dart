import 'package:hear_well/core/theme/app_gradients.dart';
import 'package:hear_well/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for MethodChannel

class Application extends StatefulWidget {
  const Application({super.key});

  @override
  State<Application> createState() => _ApplicationState();
}

List<Widget> _screens = [HomeScreen(), SettingScreen(), ProfileScreen()];

class _ApplicationState extends State<Application> {
  int _currentIndex = 0;
  static const platform = MethodChannel('com.example.hear_well/check'); // Added MethodChannel

  @override
  void initState() {
    super.initState();
    _startGlobalNativeLoopback();
  }

  @override
  void dispose() {
    _stopGlobalNativeLoopback();
    super.dispose();
  }

  Future<void> _startGlobalNativeLoopback() async {
    try {
      final String? result = await platform.invokeMethod('startAudioLoopback');
      print("Global Native Loopback started: ${result ?? ''}");
    } on PlatformException catch (e) {
      print("Failed to start global native loopback: ${e.message}");
      // Optionally, show a non-modal alert or log to a persistent store
    }
  }

  Future<void> _stopGlobalNativeLoopback() async {
    try {
      final String? result = await platform.invokeMethod('stopAudioLoopback');
      print("Global Native Loopback stopped: ${result ?? ''}");
    } on PlatformException catch (e) {
      print("Failed to stop global native loopback: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: isDark ? Color(0xFF1D1D30) : Colors.white,
            elevation: 8,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(fontSize: 12),
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
