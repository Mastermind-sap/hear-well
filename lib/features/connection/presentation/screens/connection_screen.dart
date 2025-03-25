import 'package:hear_well/core/theme/app_gradients.dart';
import 'package:hear_well/features/connection/presentation/screens/widgets/device_item.dart';
import 'package:hear_well/features/connection/presentation/screens/widgets/scanning_screen.dart';
import 'package:hear_well/features/profile/presentation/screens/widgets/gradient_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with SingleTickerProviderStateMixin {
  bool _isBluetoothOn = false;
  String errorMessage = '';

  // Permission state variables
  bool _permissionsGranted = false;
  bool _isCheckingPermissions = true;

  // Animation controller for pulse effect
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    _checkAndRequestPermissions();
    _checkBluetoothStatus();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Listen for Bluetooth state changes
    FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _isBluetoothOn = state == BluetoothAdapterState.on;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
      errorMessage = '';
    });

    try {
      Map<Permission, PermissionStatus> statuses =
          await [
            // Permission.bluetooth,
            Permission.bluetoothScan,
            // Permission.bluetoothConnect,
            Permission.location,
          ].request();
      // final btRequest = Permission.bluetooth.request();

      bool allGranted = true;
      String missingPermissions = '';

      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
          missingPermissions += '${permission.toString()}, ';
        }
      });

      if (mounted) {
        setState(() {
          _permissionsGranted = allGranted;
          _isCheckingPermissions = false;
          if (!allGranted && missingPermissions.isNotEmpty) {
            errorMessage =
                'Missing permissions: ${missingPermissions.substring(0, missingPermissions.length - 2)}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _permissionsGranted = false;
          _isCheckingPermissions = false;
          errorMessage = 'Error checking permissions: $e';
        });
      }
    }
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      final isOn =
          await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      setState(() {
        _isBluetoothOn = isOn;
      });
    } catch (e) {
      print("Error checking Bluetooth status: $e");
    }
  }

  Future<void> _toggleBluetooth() async {
    try {
      if (_isBluetoothOn) {
        // Note: Most platforms don't allow programmatically turning off Bluetooth
        print("Please turn off Bluetooth manually from settings");
      } else {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      print("Error toggling Bluetooth: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Connect Device',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: AppGradients.appBarDecoration(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(
            Theme.of(context).brightness,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Bluetooth status card with gradient
                GradientContainer(
                  gradientColors:
                      _isBluetoothOn
                          ? [
                            colorScheme.secondary.withOpacity(0.8),
                            colorScheme.secondary,
                          ]
                          : [Colors.grey.shade500, Colors.grey.shade700],
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.bluetooth,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bluetooth Status',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isBluetoothOn ? 'Connected' : 'Disconnected',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isBluetoothOn,
                          onChanged:
                              (_) =>
                                  _permissionsGranted
                                      ? _toggleBluetooth()
                                      : _checkAndRequestPermissions(),
                          activeColor: Colors.white,
                          activeTrackColor: Colors.white.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main content - Animation and action button
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animation container with pulse effect
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale:
                                    _isBluetoothOn
                                        ? _pulseAnimation.value
                                        : 1.0,
                                child: Container(
                                  width: 280,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.surfaceGradient(
                                      context,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isBluetoothOn
                                                ? colorScheme.primary
                                                : colorScheme.onSurface)
                                            .withOpacity(0.15),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: (_isBluetoothOn
                                              ? colorScheme.primary
                                              : Colors.grey)
                                          .withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Lottie.asset(
                                    'assets/lottiefiles/scanning.json',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // Action button with gradient
                          InkWell(
                            onTap:
                                _permissionsGranted
                                    ? _toggleBluetooth
                                    : _checkAndRequestPermissions,
                            child: Container(
                              width: 220,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors:
                                      _isBluetoothOn
                                          ? [
                                            colorScheme.primary,
                                            colorScheme.secondary,
                                          ]
                                          : [
                                            Colors.grey.shade400,
                                            Colors.grey.shade600,
                                          ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isBluetoothOn
                                            ? colorScheme.primary
                                            : Colors.grey)
                                        .withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isBluetoothOn
                                        ? Icons.bluetooth_connected
                                        : Icons.bluetooth_disabled,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isBluetoothOn
                                        ? 'Bluetooth On'
                                        : 'Turn On Bluetooth',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Permission warnings
                          if (!_permissionsGranted) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Permission required for Bluetooth',
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],

                          if (errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer.withOpacity(
                                  0.7,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                errorMessage,
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton:
          _isBluetoothOn
              ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Home button
                  FloatingActionButton.extended(
                    heroTag: "home_button",
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    elevation: 4,
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                  ),
                  SizedBox(width: 16),
                  // Scan devices button
                  FloatingActionButton.extended(
                    heroTag: "scan_button",
                    onPressed: () async {
                      if (_permissionsGranted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScanningScreen(),
                          ),
                        );
                        await Future.delayed(const Duration(seconds: 3));
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DeviceScreen(),
                          ),
                        );
                      } else {
                        await _checkAndRequestPermissions();
                      }
                    },
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 4,
                    icon: const Icon(Icons.search),
                    label: const Text('Scan Devices'),
                  ),
                ],
              )
              : null,
    );
  }
}
