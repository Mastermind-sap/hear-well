import 'package:echo_aid/core/theme/app_gradients.dart';
import 'package:echo_aid/core/widgets/scanning_status_indicator.dart';
import 'package:echo_aid/features/connection/presentation/screens/widgets/enhanced_device_list.dart';
import 'package:echo_aid/features/connection/presentation/screens/connection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen>
    with SingleTickerProviderStateMixin {
  List<BluetoothDevice> devices = [];
  bool isScanning = true;
  final PageController _pageController = PageController();

  // Animation controller for the pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startScan();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    // Stop any ongoing scan when disposing
    if (FlutterBluePlus.isScanningNow) {
      FlutterBluePlus.stopScan();
    }
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      devices = [];
      isScanning = true;
    });

    try {
      // Get currently connected devices
      final connectedDevices = await FlutterBluePlus.connectedDevices;
      setState(() {
        devices.addAll(connectedDevices);
      });

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      // Listen for scan results
      FlutterBluePlus.scanResults.listen((results) {
        // Filter out duplicates
        final newDevices = <BluetoothDevice>[];
        for (final result in results) {
          if (!devices.contains(result.device)) {
            newDevices.add(result.device);
          }
        }

        if (newDevices.isNotEmpty) {
          setState(() {
            devices.addAll(newDevices);
          });
        }
      });

      // When scan completes
      FlutterBluePlus.isScanning.listen((isScanning) {
        if (!isScanning && mounted) {
          setState(() {
            this.isScanning = false;
          });
        }
      });
    } catch (e) {
      print('Error scanning for devices: $e');
      setState(() {
        isScanning = false;
      });
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _showSnackBar('Connected to ${device.name}', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to connect: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Handle back button presses to go to connection screen instead of previous page
    return WillPopScope(
      onWillPop: () async {
        // Navigate to connection screen instead of going back
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ConnectionScreen()),
        );
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'Available Devices',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const ConnectionScreen(),
                ),
              );
            },
          ),
          flexibleSpace: Container(
            decoration: AppGradients.appBarDecoration(context),
          ),
          actions: [
            // Fix the vertical clipping of scanning indicator
            if (isScanning)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ScanningStatusIndicator(
                    message: "Scanning...",
                    color: Colors.white,
                  ),
                ),
              )
            else
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _startScan,
                tooltip: 'Refresh',
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.backgroundGradient(theme.brightness),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                EnhancedDeviceList(
                  devices: devices,
                  onDeviceTap: _connectToDevice,
                  isScanning: isScanning,
                ),

                // Add device count indicator with animation
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isScanning ? _pulseAnimation.value : 1.0,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(
                                0.9,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.devices,
                                  color: colorScheme.onPrimaryContainer,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "${devices.length} ${devices.length == 1 ? 'Device' : 'Devices'} Found",
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (isScanning) {
              FlutterBluePlus.stopScan();
            } else {
              _startScan();
            }
          },
          backgroundColor: isScanning ? Colors.red : colorScheme.secondary,
          label: Text(isScanning ? 'Stop' : 'Scan'),
          icon: Icon(isScanning ? Icons.stop : Icons.bluetooth_searching),
        ),
      ),
    );
  }
}
