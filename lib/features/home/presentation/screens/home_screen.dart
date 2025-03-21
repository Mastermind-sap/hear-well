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

  // New audio enhancement controls
  bool _noiseSuppressionEnabled = true;
  double _compressionThreshold = 0.5;
  double _compressionRatio = 2.0;
  double _adaptiveGain = 1.0;
  int _selectedEqBand = 0;
  List<double> _eqValues = List.filled(10, 1.0);

  @override
  void initState() {
    super.initState();
    _eqValues = List.from(_audioService.equalizer);
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
      appBar: AppBar(title: const Text("Echo Aid")),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Audio Enhancement Controls",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // Volume control
            ListTile(
              title: const Text('Volume'),
              subtitle: Slider(
                min: 0,
                max: 100,
                value: _currentVolume,
                onChanged: (val) {
                  setState(() => _currentVolume = val);
                  _audioService.setVolume(val / 100);
                },
              ),
              trailing: Text('${_currentVolume.toStringAsFixed(0)}%'),
            ),

            // Noise gate controls
            ExpansionTile(
              title: const Text('Noise Gate'),
              children: [
                ListTile(
                  title: const Text('Threshold'),
                  subtitle: Slider(
                    min: 0.0,
                    max: 0.5,
                    value: _noiseThreshold,
                    onChanged: (val) {
                      setState(() => _noiseThreshold = val);
                      _audioService.setNoiseThreshold(val);
                    },
                  ),
                  trailing: Text(_noiseThreshold.toStringAsFixed(3)),
                ),
                SwitchListTile(
                  title: const Text('Advanced Noise Suppression'),
                  value: _noiseSuppressionEnabled,
                  onChanged: (val) {
                    setState(() => _noiseSuppressionEnabled = val);
                    _audioService.setNoiseSuppressionEnabled(val);
                  },
                ),
              ],
            ),

            // Amplitude controls
            ExpansionTile(
              title: const Text('Amplitude Enhancement'),
              children: [
                ListTile(
                  title: const Text('Decibel Boost'),
                  subtitle: Slider(
                    min: 1.0,
                    max: 5.0,
                    value: _decibelBoost,
                    onChanged: (val) {
                      setState(() => _decibelBoost = val);
                      _audioService.setDecibelBoost(val);
                    },
                  ),
                  trailing: Text('${_decibelBoost.toStringAsFixed(1)}x'),
                ),
                ListTile(
                  title: const Text('Adaptive Gain'),
                  subtitle: Slider(
                    min: 0.5,
                    max: 3.0,
                    value: _adaptiveGain,
                    onChanged: (val) {
                      setState(() => _adaptiveGain = val);
                      _audioService.setAdaptiveGain(val);
                    },
                  ),
                  trailing: Text('${_adaptiveGain.toStringAsFixed(1)}x'),
                ),
              ],
            ),

            // Dynamic range compression
            ExpansionTile(
              title: const Text('Dynamic Range Compression'),
              children: [
                ListTile(
                  title: const Text('Threshold'),
                  subtitle: Slider(
                    min: 0.1,
                    max: 0.9,
                    value: _compressionThreshold,
                    onChanged: (val) {
                      setState(() => _compressionThreshold = val);
                      _audioService.setCompression(
                        _compressionThreshold,
                        _compressionRatio,
                      );
                    },
                  ),
                  trailing: Text(_compressionThreshold.toStringAsFixed(2)),
                ),
                ListTile(
                  title: const Text('Compression Ratio'),
                  subtitle: Slider(
                    min: 1.0,
                    max: 5.0,
                    value: _compressionRatio,
                    onChanged: (val) {
                      setState(() => _compressionRatio = val);
                      _audioService.setCompression(
                        _compressionThreshold,
                        _compressionRatio,
                      );
                    },
                  ),
                  trailing: Text('${_compressionRatio.toStringAsFixed(1)}:1'),
                ),
              ],
            ),

            // Equalizer
            ExpansionTile(
              title: const Text('Frequency Equalizer'),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    10,
                    (index) => GestureDetector(
                      onTap: () {
                        setState(() => _selectedEqBand = index);
                      },
                      child: Container(
                        width: 25,
                        height: 100,
                        decoration: BoxDecoration(
                          color:
                              _selectedEqBand == index
                                  ? Colors.blue
                                  : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 20,
                              height: _eqValues[index] * 80,
                              color: Colors.green,
                            ),
                            Text(
                              '${index + 1}',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Slider(
                  min: 0.1,
                  max: 3.0,
                  value: _eqValues[_selectedEqBand],
                  onChanged: (val) {
                    setState(() {
                      _eqValues[_selectedEqBand] = val;
                      _audioService.setEqualizer(_eqValues);
                    });
                  },
                ),
                Text(
                  'Band ${_selectedEqBand + 1}: ${_eqValues[_selectedEqBand].toStringAsFixed(2)}x',
                ),
              ],
            ),

            // Audio waveform
            const Divider(),
            const Text(
              'Audio Waveform',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 100,
              child: StreamBuilder<Float32List>(
                stream: _audioService.waveStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Center(child: WaveWidget(data: snapshot.data!));
                  }
                  return const Center(child: Text("Awaiting audio..."));
                },
              ),
            ),
          ],
        ),
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
