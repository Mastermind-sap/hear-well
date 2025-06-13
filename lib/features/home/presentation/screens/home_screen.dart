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
import 'package:vibration/vibration.dart';
// Add import for translations
import 'package:hear_well/core/localization/app_localizations.dart';
import 'package:hear_well/core/localization/translation_helper.dart';
import 'package:hear_well/features/home/presentation/widgets/audio_classification_card.dart';
import 'package:hear_well/features/home/presentation/screens/hearing_resources_screen.dart';

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
  bool _audioServiceActive =
      false; // This will now primarily reflect flutter_sound based service
  static const platform = MethodChannel('com.example.hear_well/check');
  bool _isConnected = true;

  // --- State variables for Native Audio Loopback ---
  bool _isNativeLoopbackActive = false;
  String _nativeLoopbackStatusMessage = "Audio Loopback: Initializing...";
  StreamSubscription? _nativeAudioFrameSubscription;
  // --- End of state variables ---

  List<String> _yamnetPredictions = [];
  List<double> _yamnetScores = [];

  final List<String> _dangerLabels = [
    "Vehicle horn, car horn, honking",
    "Siren",
    "Alarm",
    "Fire alarm",
    "Police car (siren)",
    "Ambulance (siren)",
    "Fire engine, fire truck (siren)",
    "Explosion",
    "Gunshot, gunfire",
    "Machine gun",
    "Artillery fire",
    "Fireworks",
    "Burst, pop",
    "Eruption",
    "Boom",
  ]; // Add danger or alert labels

  @override
  void initState() {
    super.initState();
    _listenToYamnetEvents();
    _initializeAudioFeatures();
  }

  void _listenToYamnetEvents() {
    const EventChannel yamnetEventChannel = EventChannel(
      'com.example.hear_well/yamnet_events',
    );
    yamnetEventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is List) {
          setState(() {
            _yamnetPredictions =
                event.map((e) => e['label'] as String).toList();
            _yamnetScores = event.map((e) => e['score'] as double).toList();
          });

          // Check if the top prediction is a danger or alert sound
          if (_yamnetPredictions.isNotEmpty &&
              _dangerLabels.contains(_yamnetPredictions[0])) {
            _triggerVibration();
          }
        }
      },
      onError: (dynamic error) {
        debugPrint('YAMNet Error: ${error.message}');
      },
    );
  }

  void _triggerVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500); // Vibrate for 500ms
    }
  }

  Future<void> _initializeAudioFeatures() async {
    await _checkConnectionAndShowDialog();
    // await _initializeDartServices(); // If you have other Dart-specific audio services
    await _checkNativeLoopbackStatus(); // Ensure this is called to check status and start listener
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
      final List<dynamic> result = await platform.invokeMethod(
        'getConnectedA2DPDevices',
      );
      return result.map((e) => e.toString()).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to get devices: ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to get connected devices: ${e.message}"),
          ),
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
      debugPrint(
        "HomeScreen: Native loopback is active. Dart audio service not started.",
      );
      if (mounted) {
        setState(() {
          _nativeLoopbackStatusMessage =
              "Native Loopback: Active. Stop to use other audio features.";
        });
      }
      return;
    }
    await _audioService
        .startLivePlayback(); // This is the flutter_sound based service
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
        debugPrint(
          "HomeScreen: Native loopback active. Stop it manually to transcribe.",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Please stop Native Loopback to start transcription.",
              ),
            ),
          );
          setState(() {
            _nativeLoopbackStatusMessage =
                "Native Loopback: Active. Stop to use transcription.";
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

  // --- Native Loopback Control Methods (Consider removing if fully global) ---
  // Or keep for local status display if needed, but not for starting/stopping
  Future<void> _checkNativeLoopbackStatus() async {
    try {
      final bool isActive = await platform.invokeMethod('isNativeLoopbackActive');
      if (mounted) {
        setState(() {
          _isNativeLoopbackActive = isActive;
          _nativeLoopbackStatusMessage = isActive 
              ? "Native Loopback: Active (Global)" 
              : "Native Loopback: Inactive (Global)";
        });
        if (isActive) {
          _listenToNativeAudioFrames(); // Start listening for visualization if active
        } else {
          // If loopback is not active, ensure we are not trying to listen to frames.
          _nativeAudioFrameSubscription?.cancel();
          _nativeAudioFrameSubscription = null;
          // Consider if _audioService.stopListeningToNativeStream(); is needed here
          // if AudioService maintains its own event channel listening independent of subscription.
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _isNativeLoopbackActive = false;
          _nativeLoopbackStatusMessage = "Native Loopback: Error checking status (${e.message})";
          _nativeAudioFrameSubscription?.cancel(); // Also cancel on error
          _nativeAudioFrameSubscription = null;
        });
      }
    }
  }

  // Optional: Button on home screen to explicitly stop if global management fails or for user override
  Future<void> _userStopNativeLoopback() async {
    try {
      await platform.invokeMethod('stopAudioLoopback');
      _checkNativeLoopbackStatus(); // Update local status
    } on PlatformException catch (e) {
      print("Failed to stop native loopback from home: ${e.message}");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error stopping loopback: ${e.message}"))
        );
      }
    }
  }

  Future<void> _userStartNativeLoopback() async {
    try {
      await platform.invokeMethod('startAudioLoopback');
      _checkNativeLoopbackStatus(); // Update local status
    } on PlatformException catch (e) {
      print("Failed to start native loopback from home: ${e.message}");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error starting loopback: ${e.message}"))
        );
      }
    }
  }

  // --- End of Native Loopback Control Methods ---

  Future<void> _startNativeLoopback({bool showErrorSnackbar = true}) async {
    if (_audioServiceActive) {
      await _stopDartAudioService();
    }
    if (_isTranscribing) {
      _transcriptionService.stopListening();
      _transcriptionService.dispose();
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
      });
    }

    try {
      final String? result = await platform.invokeMethod('startAudioLoopback');
      if (!mounted) return;
      setState(() {
        _isNativeLoopbackActive = true;
        _nativeLoopbackStatusMessage =
            "Native Loopback: Active. ${result ?? ''}";
      });
      _listenToNativeAudioFrames(); // Start listening to frames from AudioService
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _isNativeLoopbackActive = false;
        _nativeLoopbackStatusMessage =
            "Native Loopback Error (Start): ${e.message}";
      });
      if (showErrorSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error starting native loopback: ${e.message}"),
          ),
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
        _nativeLoopbackStatusMessage =
            "Native Loopback: Stopped. ${result ?? ''}";
      });
      await _audioService.stopListeningToNativeStream();
      _nativeAudioFrameSubscription?.cancel();
      _nativeAudioFrameSubscription = null;
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        // Keep _isNativeLoopbackActive true if stop fails, or set to false?
        // For now, assume it might still be active on native side if platform call fails.
        _nativeLoopbackStatusMessage =
            "Native Loopback Error (Stop): ${e.message}";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error stopping native loopback: ${e.message}"),
          ),
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
    _audioService
        .startListeningToNativeStream(); // Tell AudioService to listen to platform events
    _nativeAudioFrameSubscription = _audioService.nativeAudioFrameStream.listen(
      (Uint8List frame) {
        // Here, you receive the raw Uint8List audio frames from the native side.
        // You can pass them to a visualizer or a processing isolate.
        // For now, let's just print a confirmation.
        // debugPrint("HomeScreen: Received native audio frame, length: ${frame.length}");

        // Example: Update a waveform visualizer that takes Uint8List
        // if (mounted && _isNativeLoopbackActive) {
        //   // Assuming you have a StreamController for Uint8List waveform in HomeScreen or a direct widget update
        //   // _nativeWaveformController.add(frame);
        // }
      },
      onError: (error) {
        debugPrint("HomeScreen: Error in native audio frame stream: $error");
        if (mounted) {
          setState(() {
            _nativeLoopbackStatusMessage = "Native Loopback: Stream error.";
          });
        }
      },
      onDone: () {
        debugPrint("HomeScreen: Native audio frame stream done.");
        if (mounted && _isNativeLoopbackActive) {
          // If it was active and stream ends, update status
          setState(() {
            _nativeLoopbackStatusMessage = "Native Loopback: Stream ended.";
            // _isNativeLoopbackActive = false; // Decide if stream ending means loopback is inactive
          });
        }
      },
    );
  }

  // Helper function to calculate dB from PCM data
  double _calculateDbFromPcm(Uint8List pcmData) {
    if (pcmData.isEmpty || pcmData.lengthInBytes < 2) {
      return -120.0; // Represents silence or no data
    }

    Int16List samples;
    try {
      // Ensure the buffer is aligned and has an even number of bytes for Int16 view
      if (pcmData.offsetInBytes % 2 != 0 || pcmData.lengthInBytes % 2 != 0) {
        final Uint8List alignedData = Uint8List.fromList(
          pcmData,
        ); // Create a copy if not aligned
        samples = alignedData.buffer.asInt16List(
          alignedData.offsetInBytes,
          alignedData.lengthInBytes ~/ 2,
        );
      } else {
        samples = pcmData.buffer.asInt16List(
          pcmData.offsetInBytes,
          pcmData.lengthInBytes ~/ 2,
        );
      }
    } catch (e) {
      debugPrint("Error creating Int16List for dB calculation: $e");
      return -120.0;
    }

    if (samples.isEmpty) {
      return -120.0;
    }

    double sumOfSquares = 0.0;
    for (int sampleValue in samples) {
      sumOfSquares += sampleValue * sampleValue;
    }

    double meanSquare = sumOfSquares / samples.length;
    double rms = math.sqrt(meanSquare);

    if (rms == 0) {
      return -120.0; // Silence, avoid log(0)
    }

    const double maxAmplitude = 32767.0; // Max amplitude for 16-bit signed PCM
    // Calculate dBFS (decibels relative to full scale)
    double dbfs =
        20 *
        math.log(rms / maxAmplitude) /
        math.ln10; // log10(x) = log(x) / ln(10)

    return dbfs.isFinite ? dbfs : -120.0; // Ensure finite value, clamp if not
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
                        _isConnected ? colorScheme.primary : Colors.red,
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
                // Classification card
                const SizedBox(height: 16),
                AudioClassificationCard(
                  yamnetPredictions: _yamnetPredictions,
                  yamnetScores: _yamnetScores,
                  dangerLabels: _dangerLabels,
                ),

                // Add this new Resources Card
                const SizedBox(height: 16),
                _buildResourcesCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Audio level indicator that shows current decibel level
  Widget _buildAudioLevelIndicator() {
    if (_isNativeLoopbackActive) {
      return SizedBox(
        height: 40, // Keep consistent height
        child: StreamBuilder<Uint8List>(
          stream: _audioService.nativeAudioFrameStream,
          builder: (context, snapshot) {
            double dbLevel = -60.0; // Default for UI
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              dbLevel = _calculateDbFromPcm(snapshot.data!);
            }
            // Ensure dbLevel is not too low for UI normalization, e.g., clamp at -60dB for display
            dbLevel = math.max(dbLevel, -60.0);

            double normalizedLevel =
                (dbLevel + 60) / 60; // Normalize for UI (-60dB to 0dB range)
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
    } else {
      // Original implementation when native loopback is not active
      return SizedBox(
        height: 40,
        child: StreamBuilder<double>(
          stream:
              _audioService.decibelStream, // Uses flutter_sound based decibels
          builder: (context, snapshot) {
            double dbLevel = snapshot.data ?? -60.0;
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
  }

  // Waveform visualizer with improved constraints
  Widget _buildWaveformVisualizer() {
    if (_isNativeLoopbackActive) {
      return StreamBuilder<Uint8List>(
        // Listen to Uint8List from native audio stream
        stream: _audioService.nativeAudioFrameStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return Center(
              // WaveWidget now expects Uint8List
              child: ClipRect(child: WaveWidget(data: snapshot.data!)),
            );
          }
          return Center(child: Text(context.tr("Awaiting Audio")));
        },
      );
    } else {
      // Fallback or placeholder when native loopback is not active
      return Center(child: Text(context.tr("Audio Loopback Inactive")));
    }
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
      MaterialPageRoute(builder: (context) => const ConnectionScreen()),
    ).then((_) {
      // When returning from the settings screen, check connection again
      _checkConnectionAndShowDialog();
    });
  }

  // Add this new method to HomeScreen class
  Widget _buildResourcesCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            children: [
              Row(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr("hearing_resources"),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                context.tr("resources_description"),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HearingResourcesScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.tr("view_resources")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaveWidget extends StatelessWidget {
  final Uint8List data; // Changed from Float32List to Uint8List
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
  final Uint8List data; // Changed from Float32List to Uint8List
  _WavePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final double margin = size.width * 0.05; // 5% margin
    final midY = size.height / 2;

    // Convert Uint8List to Int16List
    // Each sample is 16-bit (2 bytes).
    // Ensure data.lengthInBytes is even and data.offsetInBytes is aligned for Int16List view.
    // For simplicity, assuming data is well-formed.
    if (data.isEmpty || data.lengthInBytes < 2) {
      return;
    }

    // Create an Int16List view of the Uint8List data.
    // This assumes the byte order of the data matches the platform's native byte order.
    // For PCM data from Android, it's typically Little Endian. Dart's ByteData can be used for explicit control if needed.
    Int16List samples;
    try {
      // Ensure the buffer is aligned and has an even number of bytes for Int16 view
      if (data.offsetInBytes % 2 != 0 || data.lengthInBytes % 2 != 0) {
        // If not aligned or odd length, create a copy that is.
        // This is a fallback, ideally the source provides aligned data.
        final Uint8List alignedData = Uint8List.fromList(data);
        samples = alignedData.buffer.asInt16List(
          alignedData.offsetInBytes,
          alignedData.lengthInBytes ~/ 2,
        );
      } else {
        samples = data.buffer.asInt16List(
          data.offsetInBytes,
          data.lengthInBytes ~/ 2,
        );
      }
    } catch (e) {
      // Log error or handle, e.g. if data is not suitable for Int16List view
      debugPrint("Error creating Int16List view for waveform: $e");
      return;
    }

    final int numSamples = samples.length;
    if (numSamples == 0) return;

    // Max amplitude for a 16-bit signed integer
    const double maxAmplitude = 32767.0;

    // Scale based on available height and max amplitude
    // Ensure maxAmplitude is not zero to prevent division by zero if all samples are 0
    final double heightRatio =
        (size.height / 2 - margin) / (maxAmplitude == 0 ? 1.0 : maxAmplitude);

    final path = Path();
    final paint =
        Paint()
          ..color =
              Colors
                  .blue // Waveform color
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final usableWidth = size.width - margin * 2;
    if (usableWidth <= 0) return; // Not enough space to draw

    // Draw the waveform
    path.moveTo(margin, midY - (samples[0] * heightRatio));
    for (int i = 1; i < numSamples; i++) {
      final x = margin + (i * usableWidth / (numSamples - 1));
      final y = midY - (samples[i] * heightRatio);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
