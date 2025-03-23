import 'package:echo_aid/core/widgets/animated_pulse_container.dart';
import 'package:echo_aid/core/widgets/scanning_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';

class ScanningScreen extends StatefulWidget {
  final VoidCallback? onCancel;
  final bool isDeepScan;
  
  const ScanningScreen({
    super.key, 
    this.onCancel, 
    this.isDeepScan = false
  });

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  bool isScanning = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header text with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Finding Devices',
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
                          ? 'Performing deep scan to find all available devices'
                          : 'Scanning for nearby Bluetooth devices',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),
                    
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
                      message: 'Searching for devices...',
                      color: colorScheme.primary,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Instruction card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                            'Please ensure your devices are turned on and in pairing mode',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onBackground.withOpacity(0.7),
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
                        onPressed: widget.onCancel,
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
                        label: const Text('Cancel Scan'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}