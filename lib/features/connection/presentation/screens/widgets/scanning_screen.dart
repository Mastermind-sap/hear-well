import 'package:hear_well/core/theme/app_gradients.dart';
import 'package:hear_well/core/widgets/animated_pulse_container.dart';
import 'package:hear_well/core/widgets/scanning_status_indicator.dart';
import 'package:hear_well/features/connection/presentation/screens/connection_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
// Add translation imports
import 'package:hear_well/core/localization/translation_helper.dart';

class ScanningScreen extends StatefulWidget {
  final VoidCallback? onCancel;
  final bool isDeepScan;

  const ScanningScreen({super.key, this.onCancel, this.isDeepScan = false});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen>
    with SingleTickerProviderStateMixin {
  bool isScanning = true;
  int discoveredDevices = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Simulate device discovery (in real app this would be actual BT discovery)
    _simulateDeviceDiscovery();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Simulate finding devices over time for animation purposes
  void _simulateDeviceDiscovery() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          discoveredDevices++;
        });
        if (discoveredDevices < 5) {
          _simulateDeviceDiscovery();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Handle back button presses to go to connection screen
    return WillPopScope(
      onWillPop: () async {
        // Navigate to connection screen instead of going back
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ConnectionScreen()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
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
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.backgroundGradient(theme.brightness),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Header text with gradient
                        ShaderMask(
                          shaderCallback:
                              (bounds) => LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                          child: Text(
                            context.tr('finding_devices'),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          widget.isDeepScan
                              ? context.tr('performing_deep_scan')
                              : context.tr('scanning_nearby_bluetooth'),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Device count with animation
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return AnimatedOpacity(
                              opacity: discoveredDevices > 0 ? 1.0 : 0.0,
                              duration: Duration(milliseconds: 300),
                              child: Transform.scale(
                                scale: 0.9 + (_animationController.value * 0.1),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(
                                          0.2,
                                        ),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.devices,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "$discoveredDevices ${discoveredDevices == 1 ? context.tr('device_found') : context.tr('devices_found')}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Animation Card with pulsing effect
                        AnimatedPulseContainer(
                          duration: const Duration(seconds: 3),
                          minScale: 0.95,
                          maxScale: 1.05,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(24.0),
                          child: SizedBox(
                            height: 200,
                            width: 200,
                            child: Lottie.asset(
                              'assets/lottiefiles/scanning.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Status indicator
                        ScanningStatusIndicator(
                          message: context.tr('searching_devices'),
                          color: colorScheme.primary,
                        ),

                        const SizedBox(height: 20),

                        // Instruction card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.onBackground.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: colorScheme.primary.withOpacity(0.7),
                                size: 28,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.tr('please_ensure_devices'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onBackground.withOpacity(
                                    0.7,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom action buttons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Cancel button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                widget.onCancel ??
                                () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const ConnectionScreen(),
                                    ),
                                  );
                                },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              backgroundColor: colorScheme.errorContainer,
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.close_rounded),
                            label: Text(context.tr('cancel_scan')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
