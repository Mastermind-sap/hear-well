import 'dart:math' as math;
import 'dart:typed_data';

import 'package:echo_aid/core/theme/app_gradients.dart';
import 'package:echo_aid/features/profile/presentation/screens/widgets/gradient_container.dart';
import 'package:echo_aid/features/setting/setting.dart';
import 'package:flutter/material.dart';
import 'package:echo_aid/services/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _audioService = AudioService();
  final _transcriptionService = TranscriptionService();

  String _transcribedText = "Tap microphone to start speech recognition";
  bool _isTranscribing = false;
  bool _audioServiceActive = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Start audio enhancement by default
    await _startAudioService();
  }

  Future<void> _startAudioService() async {
    await _audioService.startLivePlayback();
    setState(() {
      _audioServiceActive = true;
    });
  }

  Future<void> _stopAudioService() async {
    await _audioService.stopLivePlayback();
    setState(() {
      _audioServiceActive = false;
    });
  }

  Future<void> _toggleTranscription() async {
    if (_isTranscribing) {
      // Stop transcription
      _transcriptionService.stopListening();

      setState(() {
        _isTranscribing = false;
        _transcribedText = "Tap microphone to start speech recognition";
      });

      _transcriptionService.dispose();
      // Resume audio service
      await _startAudioService();
    } else {
      // Stop audio service first
      await _stopAudioService();

      // Start transcription
      setState(() {
        _isTranscribing = true;
        _transcribedText = "Listening for speech...";
      });

      await _transcriptionService.initializeSpeech();

      // Start listening for transcription results
      _transcriptionService.transcriptionStreamController.stream.listen((text) {
        setState(() {
          _transcribedText = text;
        });
      });
    }
  }

  @override
  void dispose() {
    _audioService.stopLivePlayback();
    _transcriptionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Echo Aid"),
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
                              const Text(
                                "Audio Visualization",
                                style: TextStyle(
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
                              const Text(
                                "Speech Transcription",
                                style: TextStyle(
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
                  child: GradientContainer(
                    height: 90,
                    gradientColors: [
                      colorScheme.primary.withOpacity(0.8),
                      colorScheme.primary,
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
                            _audioService.currentProfile != null
                                ? Icons.check_circle
                                : Icons.equalizer,
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
                              const Text(
                                "Audio Enhancement Active",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Profile: ${_audioService.currentProfile?.name ?? 'Default'}",
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
              ],
            ),
          ),
        ),
      ),
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
        setState(() {}); // Trigger rebuild to restart animation
      },
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
                "Level: ${dbLevel.toStringAsFixed(1)} dB",
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
        return const Center(child: Text("Awaiting audio..."));
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
