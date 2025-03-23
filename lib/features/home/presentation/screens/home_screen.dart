import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:echo_aid/services/services.dart';
import 'package:echo_aid/features/settings/presentation/screens/settings_screen.dart';

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
    // _audioService.stopLivePlayback();
    _transcriptionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Echo Aid"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              // Navigate to settings page
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SettingsScreen(audioService: _audioService),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Audio visualization card
          Expanded(
            flex: 3,
            child: Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
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
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
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
                        IconButton(
                          icon: Icon(
                            _isTranscribing ? Icons.stop : Icons.mic,
                            color: _isTranscribing ? Colors.red : Colors.blue,
                          ),
                          onPressed: _toggleTranscription,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          // Transcribed text
                          SingleChildScrollView(
                            child: Text(
                              _transcribedText,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),

                          // Visualize active transcription
                          if (_isTranscribing)
                            Positioned(
                              right: 0,
                              top: 0,
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

          // Active profile information
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: Text(
                "Active Profile: ${_audioService.currentProfile?.name ?? 'Default'}",
              ),
              subtitle: const Text("Tap Settings to adjust audio enhancement"),
              leading: const Icon(Icons.equalizer),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            SettingsScreen(audioService: _audioService),
                  ),
                );
              },
            ),
          ),
        ],
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
