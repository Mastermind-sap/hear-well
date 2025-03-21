import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fftea/fftea.dart';
import 'dart:math' as math;

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final _streamCtrl = StreamController<Uint8List>();

  final FlutterSoundHelper _helper = FlutterSoundHelper();
  final StreamController<Float32List> _waveStreamCtrl =
      StreamController<Float32List>.broadcast();

  static const int sampleRate = 48100;
  static const int numOfChannels = 2;

  double noiseThreshold = 0.01;
  double decibelBoost = 1.0;

  // Audio enhancement parameters
  List<double> _equalizer = List.filled(10, 1.0); // 10-band equalizer
  double _compressionThreshold = 0.5;
  double _compressionRatio = 2.0;
  bool _noiseSuppressionEnabled = true;
  double _adaptiveGain = 1.0;

  void setNoiseThreshold(double threshold) {
    noiseThreshold = threshold;
  }

  void setDecibelBoost(double boost) {
    decibelBoost = boost;
  }

  // Frequency EQ settings
  void setEqualizer(List<double> bands) {
    if (bands.length == _equalizer.length) {
      _equalizer = List.from(bands);
    }
  }

  // Dynamic range compression settings
  void setCompression(double threshold, double ratio) {
    _compressionThreshold = threshold;
    _compressionRatio = ratio;
  }

  Future<void> setNoiseSuppressionEnabled(bool enabled) async {
    // print("Noise suppression enabled: $enabled");
    await FlutterSoundNoiseSuppressor.enable();
    _noiseSuppressionEnabled = enabled;
  }

  void setAdaptiveGain(double gain) {
    _adaptiveGain = gain;
  }

  // Enhances audio by applying frequency-specific amplification
  Float32List applyEqualization(Float32List audioData) {
    final int segmentSize = _equalizer.length;
    final result = Float32List(audioData.length);

    // Apply simple time-domain equalization (safer approach)
    for (int i = 0; i < audioData.length; i++) {
      // Map sample index to frequency band (simplified approach)
      final int band = (i % segmentSize);
      result[i] = audioData[i] * _equalizer[band];
    }

    // If audioData is long enough, try FFT-based equalization
    if (audioData.length >= 512) {
      try {
        // Create FFT instance with a reasonable size
        final int fftSize = 512;
        final fft = FFT(fftSize);

        // Process audio in segments
        for (
          int offset = 0;
          offset < audioData.length - fftSize;
          offset += fftSize ~/ 2
        ) {
          // Extract segment for processing
          final segment = audioData.sublist(
            offset,
            math.min(offset + fftSize, audioData.length),
          );

          // Apply window function to reduce spectral leakage
          final windowedData = Float32List(fftSize);
          for (int i = 0; i < segment.length; i++) {
            // Simple Hann window
            windowedData[i] =
                segment[i] *
                0.5 *
                (1 - math.cos(2 * math.pi * i / (segment.length - 1)));
          }

          // Perform FFT and get the frequency domain representation
          // Use the correct type Float64x2List instead of List<Float64x2>
          final Float64x2List spectrum = fft.realFft(windowedData);

          // Apply equalization in frequency domain
          for (int i = 0; i < spectrum.length; i++) {
            // Map FFT bin to equalizer band (simple mapping)
            int band = (i * _equalizer.length ~/ spectrum.length).clamp(
              0,
              _equalizer.length - 1,
            );

            // Apply gain to both real and imaginary parts
            final double gain = _equalizer[band];
            // Create a new Float64x2 with the gain applied
            spectrum[i] = Float64x2(spectrum[i].x * gain, spectrum[i].y * gain);
          }

          // Inverse FFT to time domain - need to convert from Float64List to Float32List
          final Float64List rawProcessedData = fft.realInverseFft(spectrum);
          final Float32List processedData = Float32List(
            rawProcessedData.length,
          );

          // Copy and convert the Float64List to Float32List
          for (int i = 0; i < rawProcessedData.length; i++) {
            processedData[i] = rawProcessedData[i].toDouble();
          }

          // Apply overlap-add method to the result
          // First half (overlap with previous segment)
          for (int i = 0; i < fftSize ~/ 2 && offset + i < result.length; i++) {
            result[offset + i] = (result[offset + i] + processedData[i] * 0.5);
          }

          // Second half (will overlap with next segment)
          for (
            int i = fftSize ~/ 2;
            i < processedData.length && offset + i < result.length;
            i++
          ) {
            result[offset + i] = processedData[i] * 0.5;
          }
        }
      } catch (e) {
        print("FFT processing error: $e");
        // Fall back to the already computed simple result
      }
    }

    return result;
  }

  // Apply dynamic range compression
  Float32List applyCompression(Float32List audioData) {
    final result = Float32List(audioData.length);

    for (int i = 0; i < audioData.length; i++) {
      final double absValue = audioData[i].abs();
      if (absValue > _compressionThreshold) {
        // Compress values above threshold
        final double excess = absValue - _compressionThreshold;
        final double compressed =
            _compressionThreshold + (excess / _compressionRatio);
        result[i] = (audioData[i] >= 0 ? compressed : -compressed);
      } else {
        result[i] = audioData[i];
      }
    }
    return result;
  }

  // Apply noise suppression (spectral subtraction simplified)
  Float32List applyNoiseSuppression(Float32List audioData) {
    if (!_noiseSuppressionEnabled) return audioData;

    final result = Float32List(audioData.length);
    for (int i = 0; i < audioData.length; i++) {
      // Simple noise gate implementation
      // print("Noise threshold: $noiseThreshold");
      // print(audioData[i].abs());
      if (audioData[i].abs() < noiseThreshold * 2) {
        result[i] = 0; // Suppress noise below threshold
      } else {
        // Reduce noise by subtracting estimated noise floor
        // result[i] = audioData[i] - (audioData[i].sign * noiseThreshold);
        result[i] = audioData[i];
      }
    }
    return result;
  }

  // Apply adaptive gain control
  Float32List applyAdaptiveGain(Float32List audioData) {
    if (_adaptiveGain <= 0) return audioData;

    // Find peak amplitude
    double peak = 0;
    for (int i = 0; i < audioData.length; i++) {
      if (audioData[i].abs() > peak) peak = audioData[i].abs();
    }

    // Calculate adaptive gain factor (avoid division by zero)
    double factor =
        peak > 0.01 ? math.min(1.0 / peak, _adaptiveGain) : _adaptiveGain;

    // Apply gain
    final result = Float32List(audioData.length);
    for (int i = 0; i < audioData.length; i++) {
      result[i] = audioData[i] * factor;
    }
    return result;
  }

  Future<void> startLivePlayback() async {
    await _recorder.openRecorder();
    await _player.openPlayer();

    await _player.startPlayerFromStream(
      codec: Codec.pcmFloat32,
      sampleRate: sampleRate,
      numChannels: numOfChannels,
      interleaved: true,
      bufferSize: 1024,
    );

    _streamCtrl.stream.listen((data) async {
      // We need to manually convert Uint8List to Float32List since the helper doesn't have this method
      Float32List floatData = convertUint8ToFloat32(data);

      // Apply audio enhancements in sequence
      if (floatData.isNotEmpty) {
        floatData = applyNoiseSuppression(floatData);
        floatData = applyEqualization(floatData);
        floatData = applyCompression(floatData);
        floatData = applyAdaptiveGain(floatData);

        // Basic noise gate and amplification (original functionality)
        for (int i = 0; i < floatData.length; i++) {
          if (floatData[i].abs() < noiseThreshold) {
            floatData[i] = 0;
          } else {
            floatData[i] *= decibelBoost;
          }
        }

        // Convert back to Uint8List for playback
        final processedData = convertFloat32ToUint8(floatData);
        await _player.feedUint8FromStream(processedData);

        // Send processed waveform data to the stream
        _waveStreamCtrl.add(floatData);
      } else {
        // If conversion failed, use the original data
        await _player.feedUint8FromStream(data);
      }
    });

    await _recorder.startRecorder(
      codec: Codec.pcmFloat32,
      sampleRate: sampleRate,
      numChannels: numOfChannels,
      audioSource: AudioSource.defaultSource,
      toStream: _streamCtrl.sink,
    );
  }

  // Custom conversion from Uint8List to Float32List
  Float32List convertUint8ToFloat32(Uint8List uint8Data) {
    try {
      // 4 bytes per float in IEEE 754 format
      final int floatCount = uint8Data.length ~/ 4;

      // Create ByteData view for proper binary conversion
      final byteData = ByteData.sublistView(uint8Data);

      // Create and populate Float32List
      final result = Float32List(floatCount);
      for (int i = 0; i < floatCount; i++) {
        result[i] = byteData.getFloat32(i * 4, Endian.little);
      }

      return result;
    } catch (e) {
      print("Error converting Uint8List to Float32List: $e");
      return Float32List(0);
    }
  }

  // Custom conversion from Float32List to Uint8List
  Uint8List convertFloat32ToUint8(Float32List floatData) {
    try {
      // 4 bytes per float in IEEE 754 format
      final resultBytes = Uint8List(floatData.length * 4);
      final byteData = ByteData.sublistView(resultBytes);

      // Fill the byte buffer with float values
      for (int i = 0; i < floatData.length; i++) {
        byteData.setFloat32(i * 4, floatData[i], Endian.little);
      }

      return resultBytes;
    } catch (e) {
      print("Error converting Float32List to Uint8List: $e");
      return Uint8List(0);
    }
  }

  Future<void> stopLivePlayback() async {
    await _recorder.stopRecorder();
    await _player.stopPlayer();
  }

  void setVolume(double vol) async {
    print("Setting volume to $vol");
    await _player.setVolume(vol);
  }

  Stream<Float32List> get waveStream => _waveStreamCtrl.stream;

  // Expose equalization bands for UI
  List<double> get equalizer => _equalizer;
}
