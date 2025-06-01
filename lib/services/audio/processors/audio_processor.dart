import 'dart:typed_data';
import 'dart:math' as math;
import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
import 'package:hear_well/services/audio/utils/audio_utils.dart'; // Added import

class AudioProcessor {
  // Audio enhancement parameters
  List<double> _equalizer = List.filled(10, 1.0);
  double _compressionThreshold = 0.5;
  double _compressionRatio = 2.0;
  bool _noiseSuppressionEnabled = true;
  double _adaptiveGain = 1.0;
  double _noiseThreshold = 0.01;
  double _decibelBoost = 1.0;

  // Noise estimation variables
  List<double> _noiseFloor = List.filled(512, 0.005);
  bool _isCalibrating = false;
  int _calibrationFrames = 0;
  static const int _requiredCalibrationFrames = 10;

  // Audio statistics
  double _currentDecibel = 0.0;

  // Getters
  List<double> get equalizer => _equalizer;
  double get compressionThreshold => _compressionThreshold;
  double get compressionRatio => _compressionRatio;
  bool get isNoiseSuppressionEnabled => _noiseSuppressionEnabled;
  double get adaptiveGain => _adaptiveGain;
  double get noiseThreshold => _noiseThreshold;
  double get decibelBoost => _decibelBoost;
  double get currentDecibel => _currentDecibel;

  // Setters
  void setNoiseThreshold(double threshold) {
    _noiseThreshold = threshold;
  }

  void setDecibelBoost(double boost) {
    _decibelBoost = boost;
  }

  void setEqualizer(List<double> bands) {
    if (bands.length == _equalizer.length) {
      _equalizer = List.from(bands);
    }
  }

  void setCompression(double threshold, double ratio) {
    _compressionThreshold = threshold;
    _compressionRatio = ratio;
  }

  Future<void> setNoiseSuppressionEnabled(bool enabled) async {
    _noiseSuppressionEnabled = enabled;
  }

  void setAdaptiveGain(double gain) {
    _adaptiveGain = gain;
  }

  // Start noise floor calibration
  void startNoiseCalibration() {
    _isCalibrating = true;
    _calibrationFrames = 0;
    _noiseFloor = List.filled(512, 0.005);
  }

  // --- New method to handle Uint8List data from native stream ---
  Uint8List processUint8Audio(Uint8List data) {
    if (data.isEmpty) {
      return data;
    }

    // Convert Uint8List (typically PCM16) to Float32List
    Float32List floatData = AudioUtils.convertUint8ToFloat32(data);

    // Apply existing core processing logic
    Float32List processedFloatData = processAudio(floatData);

    // Convert processed Float32List back to Uint8List
    Uint8List processedUint8Data = AudioUtils.convertFloat32ToUint8(processedFloatData);

    return processedUint8Data;
  }
  // --- End of new method ---

  // Process the audio data with all enhancements
  Float32List processAudio(Float32List audioData) {
    if (audioData.isEmpty) return audioData;

    // Calculate audio metrics
    calculateDecibels(audioData);

    // Apply audio enhancements in sequence
    Float32List processedData = audioData;
    processedData = applyNoiseSuppression(processedData);
    processedData = applyEqualization(processedData);
    processedData = applyCompression(processedData);
    processedData = applyAdaptiveGain(processedData);

    // Basic amplification
    for (int i = 0; i < processedData.length; i++) {
      processedData[i] *= _decibelBoost;
    }

    return processedData;
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
        debugPrint("FFT processing error: $e");
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

  // Enhanced noise suppression using spectral subtraction
  Float32List applyNoiseSuppression(Float32List audioData) {
    if (!_noiseSuppressionEnabled) return audioData;

    // Create result buffer
    final result = Float32List(audioData.length);

    // Basic time-domain noise gate
    for (int i = 0; i < audioData.length; i++) {
      if (audioData[i].abs() < _noiseThreshold * 2) {
        result[i] = 0; // Suppress very low signals
      } else {
        // Soft noise reduction by subtracting estimated noise floor
        double signalStrength = audioData[i].abs() - _noiseThreshold;
        if (signalStrength <= 0) {
          result[i] = 0;
        } else {
          // Keep original sign but reduce magnitude
          result[i] = audioData[i].sign * signalStrength;
        }
      }
    }

    // If we have enough data, try spectral subtraction
    if (audioData.length >= 512) {
      try {
        final fft = FFT(512);

        // Process in frames
        for (int offset = 0; offset < audioData.length - 512; offset += 256) {
          final frame = audioData.sublist(offset, offset + 512);

          // Apply window
          final windowed = Float32List(512);
          for (int i = 0; i < frame.length; i++) {
            // Hann window
            windowed[i] =
                frame[i] *
                0.5 *
                (1 - math.cos(2 * math.pi * i / (frame.length - 1)));
          }

          // Perform FFT
          final spectrum = fft.realFft(windowed);

          // Update noise floor during calibration
          if (_isCalibrating) {
            for (int i = 0; i < spectrum.length; i++) {
              final magnitude = math.sqrt(
                spectrum[i].x * spectrum[i].x + spectrum[i].y * spectrum[i].y,
              );
              _noiseFloor[i] =
                  (_noiseFloor[i] * _calibrationFrames + magnitude) /
                  (_calibrationFrames + 1);
            }

            _calibrationFrames++;
            if (_calibrationFrames >= _requiredCalibrationFrames) {
              _isCalibrating = false;
            }
          }

          // Apply spectral subtraction
          for (int i = 0; i < spectrum.length; i++) {
            // Calculate magnitude and phase
            final real = spectrum[i].x;
            final imag = spectrum[i].y;
            final magnitude = math.sqrt(real * real + imag * imag);
            final phase = math.atan2(imag, real);

            // Subtract noise floor with spectral floor to avoid musical noise
            final double spectralFloor = 0.02; // Minimum spectral floor
            double newMagnitude =
                magnitude - (_noiseFloor[i] * _noiseThreshold * 10);
            if (newMagnitude < magnitude * spectralFloor) {
              newMagnitude = magnitude * spectralFloor;
            }

            // Convert back to rectangular form
            spectrum[i] = Float64x2(
              newMagnitude * math.cos(phase),
              newMagnitude * math.sin(phase),
            );
          }

          // Convert back to time domain
          final Float64List processedFrameFloat64 = fft.realInverseFft(
            spectrum,
          );
          final processedFrame = Float32List(processedFrameFloat64.length);
          for (int i = 0; i < processedFrameFloat64.length; i++) {
            processedFrame[i] = processedFrameFloat64[i].toDouble();
          }

          // Overlap-add
          for (int i = 0; i < 256 && offset + i < result.length; i++) {
            result[offset + i] += processedFrame[i] * 0.5;
          }
          for (int i = 256; i < 512 && offset + i < result.length; i++) {
            result[offset + i] = processedFrame[i] * 0.5;
          }
        }
      } catch (e) {
        debugPrint("Error in spectral noise reduction: $e");
        // We'll fall back to the simpler noise gate results
      }
    }

    return result;
  }

  // Calculate audio level in decibels
  double calculateDecibels(Float32List audioData) {
    if (audioData.isEmpty) return -96.0;

    // Calculate RMS (Root Mean Square)
    double sumOfSquares = 0;
    for (int i = 0; i < audioData.length; i++) {
      sumOfSquares += audioData[i] * audioData[i];
    }

    double rms = math.sqrt(sumOfSquares / audioData.length);

    // Convert to decibels (dB)
    // Using a reference of 1.0 for full scale
    // -20 * log10(1.0) = 0dB (maximum)
    double db = 0;
    if (rms > 0) {
      db = 20 * math.log(rms) / math.ln10;
    } else {
      db = -96; // Minimum dB (near silence)
    }

    // Smooth the readings
    _currentDecibel = _currentDecibel * 0.8 + db * 0.2;

    return _currentDecibel;
  }
}
