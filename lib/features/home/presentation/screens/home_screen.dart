import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:hear_well/core/theme/app_gradients.dart';
import 'package:hear_well/features/connection/presentation/screens/connection_screen.dart';
import 'package:hear_well/features/profile/presentation/screens/widgets/gradient_container.dart';
import 'package:hear_well/features/setting/setting.dart';
import 'package:flutter/material.dart';
import 'package:hear_well/services/services.dart';
// Add import for translations
import 'package:hear_well/core/localization/app_localizations.dart';
import 'package:hear_well/core/localization/translation_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _audioService = AudioService();
  final _transcriptionService = TranscriptionService();
  

  String _transcribedText = "";
  bool _isTranscribing = false;
  bool _audioServiceActive = false; // This will now primarily reflect flutter_sound based service
  static const platform = MethodChannel('com.example.hear_well/check');
  bool _isConnected = true;

  // --- State variables for Native Audio Loopback ---
  bool _isNativeLoopbackActive = false;
  String _nativeLoopbackStatusMessage = "Native Loopback: Initializing...";
  StreamSubscription? _nativeAudioFrameSubscription;
  // --- End of state variables ---
  
  @override
  void initState() {
    super.initState();
    _initializeAudioFeatures();
  }

  Future<void> _initializeAudioFeatures() async {
    await _checkConnectionAndShowDialog();
    if (_isConnected) {
      // Attempt to start native loopback first
      await _startNativeLoopback(showErrorSnackbar: false); // Don't show error snackbar on initial attempt
      
      // If native loopback didn't start (e.g., permission issue handled in _startNativeLoopback),
      // and no other audio service is active, then fallback to Dart-based service.
      if (!mounted) return;
      if (!_isNativeLoopbackActive && !_audioServiceActive && !_isTranscribing) {
        // Fallback to Dart-based audio service if native failed and not transcribing
        // This line is commented out as per the request to prioritize native loopback
        // await _startDartAudioService(); 
        // If you want a fallback, uncomment the line above and ensure _startDartAudioService is defined.
        // For now, if native fails, nothing else starts automatically unless user interacts.
        debugPrint("HomeScreen: Native loopback did not start. No automatic fallback to Dart audio service for now.");
      } else if (_isNativeLoopbackActive) {
         // Listen to native audio frames if native loopback is active
        _listenToNativeAudioFrames();
      }
    }
  }
  
  Future<void> _checkConnectionAndShowDialog() async {
    final connectedDevices = await getConnectedAudioDevices();
    if (!mounted) return;
    if (connectedDevices.isEmpty) {
      setState(() {
        _isConnected = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          _showConnectionDialog();
        }
      });
    } else {
      setState(() {
        _isConnected = true;
      });
      // _initializeServices(); // Moved to _initializeAudioFeatures
    }
  }

  Future<List<String>> getConnectedAudioDevices() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getConnectedA2DPDevices');
      return result.map((e) => e.toString()).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to get devices: ${e.message}");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to get connected devices: ${e.message}")),
        );
      }
      return [];
    }
  }

  // Renamed from _initializeServices to avoid confusion
  // Future<void> _initializeDartServices() async {
  //   await _startDartAudioService();
  // }

  // Renamed from _startAudioService to be specific
  Future<void> _startDartAudioService() async {
    if (_isNativeLoopbackActive) {
      // If native is active, we shouldn't start Dart service.
      // User should stop native first via UI.
      debugPrint("HomeScreen: Native loopback is active. Dart audio service not started.");
      if(mounted) {
        setState(() {
          _nativeLoopbackStatusMessage = "Native Loopback: Active. Stop to use other audio features.";
        });
      }
      return;
    }
    await _audioService.startLivePlayback(); // This is the flutter_sound based service
    if (!mounted) return;
    setState(() {
      _audioServiceActive = true;
    });
  }

  Future<void> _stopDartAudioService() async {
    await _audioService.stopLivePlayback();
    if (!mounted) return;
    setState(() {
      _audioServiceActive = false;
    });
  }

  Future<void> _toggleTranscription() async {
    if (_isTranscribing) {
      _transcriptionService.stopListening();
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
      });
      _transcriptionService.dispose();
      // No automatic restart of any service here. User can choose.
    } else {
      if (_audioServiceActive) {
        await _stopDartAudioService();
      }
      if (_isNativeLoopbackActive) {
        // User should stop native loopback manually if they want to transcribe
        debugPrint("HomeScreen: Native loopback active. Stop it manually to transcribe.");
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please stop Native Loopback to start transcription.")),
          );
          setState(() {
            _nativeLoopbackStatusMessage = "Native Loopback: Active. Stop to use transcription.";
          });
        }
        return;
      }
      
      if (!mounted) return;
      setState(() {
        _isTranscribing = true;
        _transcribedText = tr(context, "listening_for_speech");
      });

      await _transcriptionService.initializeSpeech();
      _transcriptionService.transcriptionStreamController.stream.listen((text) {
        if (!mounted) return;
        setState(() {
          _transcribedText = text;
        });
      });
    }
  }

  Future<void> _startNativeLoopback({bool showErrorSnackbar = true}) async {
      if (_audioServiceActive) {
        await _stopDartAudioService();
      }
      if (_isTranscribing) {
        _transcriptionService.stopListening();
        _transcriptionService.dispose();
        if (!mounted) return;
        setState(() { _isTranscribing = false; });
      }

      try {
        final String? result = await platform.invokeMethod('startAudioLoopback');
        if (!mounted) return;
        setState(() {
          _isNativeLoopbackActive = true;
          _nativeLoopbackStatusMessage = "Native Loopback: Active. ${result ?? ''}";
        });
        _listenToNativeAudioFrames(); // Start listening to frames from AudioService
      } on PlatformException catch (e) {
        if (!mounted) return;
        setState(() {
          _isNativeLoopbackActive = false;
          _nativeLoopbackStatusMessage = "Native Loopback Error (Start): ${e.message}";
        });
        if (showErrorSnackbar && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error starting native loopback: ${e.message}")),
          );
        }
      }
  }

  Future<void> _stopNativeLoopback() async {
     try {
        final String? result = await platform.invokeMethod('stopAudioLoopback');
        if (!mounted) return;
        setState(() {
          _isNativeLoopbackActive = false;
          _nativeLoopbackStatusMessage = "Native Loopback: Stopped. ${result ?? ''}";
        });
        await _audioService.stopListeningToNativeStream();
        _nativeAudioFrameSubscription?.cancel();
        _nativeAudioFrameSubscription = null;
      } on PlatformException catch (e) {
        if (!mounted) return;
        setState(() {
          // Keep _isNativeLoopbackActive true if stop fails, or set to false?
          // For now, assume it might still be active on native side if platform call fails.
          _nativeLoopbackStatusMessage = "Native Loopback Error (Stop): ${e.message}";
        });
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error stopping native loopback: ${e.message}")),
          );
        }
      }
  }

  // Combined toggle, now primarily for the UI button
  Future<void> _toggleNativeLoopbackButton() async {
    if (_isNativeLoopbackActive) {
      await _stopNativeLoopback();
    } else {
      await _startNativeLoopback();
    }
  }

  void _listenToNativeAudioFrames() {
    _nativeAudioFrameSubscription?.cancel(); // Cancel any existing subscription
    _audioService.startListeningToNativeStream(); // Tell AudioService to listen to platform events
    _nativeAudioFrameSubscription = _audioService.nativeAudioFrameStream.listen((Uint8List frame) {
      // Here, you receive the raw Uint8List audio frames from the native side.
      // You can pass them to a visualizer or a processing isolate.
      // For now, let's just print a confirmation.
      // debugPrint("HomeScreen: Received native audio frame, length: ${frame.length}");
      
      // Example: Update a waveform visualizer that takes Uint8List
      // if (mounted && _isNativeLoopbackActive) {
      //   // Assuming you have a StreamController for Uint8List waveform in HomeScreen or a direct widget update
      //   // _nativeWaveformController.add(frame);
      // }
    }, onError: (error) {
      debugPrint("HomeScreen: Error in native audio frame stream: $error");
      if(mounted) {
        setState(() {
          _nativeLoopbackStatusMessage = "Native Loopback: Stream error.";
        });
      }
    }, onDone: () {
      debugPrint("HomeScreen: Native audio frame stream done.");
       if(mounted && _isNativeLoopbackActive) { // If it was active and stream ends, update status
        setState(() {
          _nativeLoopbackStatusMessage = "Native Loopback: Stream ended.";
          // _isNativeLoopbackActive = false; // Decide if stream ending means loopback is inactive
        });
      }
    });
  }

  @override
  void dispose() {
    _audioService.dispose(); // This will also stop native stream listening
    _transcriptionService.dispose();
    _nativeAudioFrameSubscription?.cancel();
    // Stop native loopback on the platform side if it's active
    if (_isNativeLoopbackActive) {
      platform.invokeMethod('stopAudioLoopback').catchError((e) {
        debugPrint("Error stopping native loopback on dispose: $e");
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_transcribedText.isEmpty && !_isTranscribing) {
      _transcribedText = tr(context, "tap_microphone_to_start");
    } else if (_isTranscribing && _transcribedText.isEmpty) {
      _transcribedText = tr(context, "listening_for_speech");
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.tr("home_title")),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Audio visualization card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      decoration: BoxDecoration(
                        gradient: AppGradients.surfaceGradient(context),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.tr("audio_visualization"),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Status indicator for audio enhancement
                              if (_audioServiceActive)
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildAudioLevelIndicator(),
                          Expanded(child: _buildWaveformVisualizer()),
                        ],
                      ),
                    ),
                  ),
                ),

                // Transcription card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: AppGradients.surfaceGradient(context),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.tr("speech_transcription"),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Add microphone button to toggle transcription
                              Material(
                                color:
                                    _isTranscribing
                                        ? Colors.red
                                        : colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: _toggleTranscription,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      _isTranscribing ? Icons.stop : Icons.mic,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Stack(
                              children: [
                                // Transcribed text
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? Colors.black12
                                            : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      _transcribedText,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ),

                                // Visualize active transcription
                                if (_isTranscribing)
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: _buildPulsatingCircle(),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Status card with gradient
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: !_isConnected ? _navigateToConnectionScreen : null,
                    child: GradientContainer(
                      height: 90,
                      gradientColors: [
                        _isConnected 
                            ? colorScheme.primary.withOpacity(0.8)
                            : Colors.red.withOpacity(0.8),
                        _isConnected 
                            ? colorScheme.primary
                            : Colors.red,
                      ],
                      padding: const EdgeInsets.all(16.0),
                      borderRadius: BorderRadius.circular(16.0),
                      child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isConnected
                                ? (_audioService.currentProfile != null
                                    ? Icons.check_circle
                                    : Icons.equalizer)
                                : Icons.bluetooth_disabled,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isConnected 
                                  ? context.tr("audio_enhancement_active")
                                  : context.tr("not_connected"),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isConnected 
                                  ? "${context.tr('profile')}: ${_audioService.currentProfile?.name ?? context.tr('default')}"
                                  : context.tr('tap_to_connect_device'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Pulsing indicator
                        StreamBuilder<double>(
                          stream: _audioService.decibelStream,
                          builder: (context, snapshot) {
                            return _buildPulsingDot(Colors.white);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // --- New Card for Native Audio Loopback Test ---
                
                ), // --- End of New Card ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppGradients.surfaceGradient(context),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.tr("native_audio_loopback"),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _toggleNativeLoopbackButton, // Updated to use the new toggle
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isNativeLoopbackActive ? Colors.redAccent : colorScheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  _isNativeLoopbackActive ? context.tr("stop_loopback") : context.tr("start_loopback"),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nativeLoopbackStatusMessage, // Updated to use new status variable
                            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.9)),
                          ),
                          // Optionally, add a visualizer for native audio frames here
                          // if (_isNativeLoopbackActive) WaveformVisualizerWidget(stream: _audioService.nativeAudioFrameStream)
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
    );
  }

  // Audio level indicator that shows current decibel level
  Widget _buildAudioLevelIndicator() {
    return SizedBox(
      height: 40,
      child: StreamBuilder<double>(
        stream: _audioService.decibelStream,
        builder: (context, snapshot) {
          double dbLevel = snapshot.data ?? -60.0;
          // Normalize to 0-1 range for UI (-60dB to 0dB)
          double normalizedLevel = (dbLevel + 60) / 60;
          normalizedLevel = normalizedLevel.clamp(0.0, 1.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${context.tr("level")}: ${dbLevel.toStringAsFixed(1)} dB",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: normalizedLevel,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  normalizedLevel < 0.5
                      ? Colors.green
                      : normalizedLevel < 0.8
                      ? Colors.orange
                      : Colors.red,
                ),
                minHeight: 10,
              ),
            ],
          );
        },
      ),
    );
  }

  // Waveform visualizer with improved constraints
  Widget _buildWaveformVisualizer() {
    return StreamBuilder<Float32List>(
      stream: _audioService.waveStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Center(
            child: ClipRect(child: WaveWidget(data: snapshot.data!)),
          );
        }
        return Center(child: Text(context.tr("awaiting_audio")));
      },
    );
  }

  // Visual indicator for active transcription
  Widget _buildPulsatingCircle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Container(
          width: 12 * (1 + value * 0.3),
          height: 12 * (1 + value * 0.3),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(1.0 - value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {}); // Trigger rebuild to restart animation
      },
    );
  }

  // Add a new widget for the pulsing activity indicator
  Widget _buildPulsingDot(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(1.0 - value * 0.5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3 * (1.0 - value)),
                blurRadius: 8 * (1 + value),
                spreadRadius: 2 * value,
              ),
            ],
          ),
        );
      },
      onEnd: () {
        setState(() {}); // Trigger rebuild to restart animation
      },
    );
  }

  // Show dialog when not connected to a device
  Future<void> _showConnectionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.tr('No Device Connected')),
          content: Text(context.tr('Connect device to continue')),
          actions: <Widget>[
            TextButton(
              child: Text(context.tr('Open Connections')),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _navigateToConnectionScreen();
              },
            ),
            TextButton(
              child: Text(context.tr('Cancel')),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Navigate to the connection screen
  void _navigateToConnectionScreen() {
    // Navigate to settings with a flag to open connections panel
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConnectionScreen(),
      ),
    ).then((_) {
      // When returning from the settings screen, check connection again
      _checkConnectionAndShowDialog();
    });
  }
}

class WaveWidget extends StatelessWidget {
  final Float32List data;
  const WaveWidget({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _WavePainter(data: data),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final Float32List data;
  _WavePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final double margin = size.width * 0.05; // 5% margin
    final midY = size.height / 2;

    // Find the max amplitude in the data to scale properly
    double maxAmplitude = 0.01; // Prevent division by zero
    for (int i = 0; i < data.length; i++) {
      maxAmplitude = math.max(maxAmplitude, data[i].abs());
    }

    // Scale based on available height and max amplitude
    final double heightRatio =
        (size.height / 2 - margin) / math.max(1.0, maxAmplitude);

    // Use a path for smoother rendering
    final path = Path();
    final paint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final usableWidth = size.width - margin * 2;

    // Draw the waveform
    bool firstPoint = true;
    for (int i = 0; i < data.length; i++) {
      final x = margin + (i * usableWidth / (data.length - 1));
      final y = midY - (data[i] * heightRatio);

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
