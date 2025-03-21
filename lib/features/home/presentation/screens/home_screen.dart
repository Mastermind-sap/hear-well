import 'dart:typed_data';

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
  double _currentVolume = 50;
  double _noiseThreshold = 0.01;
  double _decibelBoost = 1.0;

  @override
  void initState() {
    super.initState();
    _audioService.startLivePlayback();
  }

  @override
  void dispose() {
    _audioService.stopLivePlayback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("WORKING"),
          Slider(
            min: 0,
            max: 100,
            value: _currentVolume,
            onChanged: (val) {
              setState(() => _currentVolume = val);
              _audioService.setVolume(val / 100);
            },
          ),
          Text('Noise Threshold'),
          Slider(
            min: 0.0,
            max: 0.05,
            value: _noiseThreshold,
            onChanged: (val) {
              setState(() => _noiseThreshold = val);
              _audioService.setNoiseThreshold(val);
            },
          ),
          Text('Decibel Boost'),
          Slider(
            min: 1.0,
            max: 5.0,
            value: _decibelBoost,
            onChanged: (val) {
              setState(() => _decibelBoost = val);
              _audioService.setDecibelBoost(val);
            },
          ),
          StreamBuilder<Float32List>(
            stream: _audioService.waveStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Center(child: WaveWidget(data: snapshot.data!));
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

class WaveWidget extends StatelessWidget {
  final Float32List data;
  const WaveWidget({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavePainter(data: data),
      child: Center(child: const SizedBox(height: 100, width: 100)),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Float32List data;
  _WavePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final double margin = 20.0;
    final double amplitudeFactor = 4.0;
    final paint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 1.0;
    final midY = size.height / 2;
    final usableWidth = size.width - margin * 2;

    for (int i = 0; i < data.length - 1; i++) {
      final x1 = margin + (i * usableWidth / (data.length - 1));
      final y1 = midY - (data[i] * amplitudeFactor * midY);
      final x2 = margin + ((i + 1) * usableWidth / (data.length - 1));
      final y2 = midY - (data[i + 1] * amplitudeFactor * midY);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
