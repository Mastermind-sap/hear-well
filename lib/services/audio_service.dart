import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fftea/fftea.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AudioProfile {
  final String name;
  final double noiseThreshold;
  final double decibelBoost;
  final List<double> equalizer;
  final double compressionThreshold;
  final double compressionRatio;
  final bool noiseSuppressionEnabled;
  final double adaptiveGain;

  AudioProfile({
    required this.name,
    required this.noiseThreshold,
    required this.decibelBoost,
    required this.equalizer,
    required this.compressionThreshold,
    required this.compressionRatio,
    required this.noiseSuppressionEnabled,
    required this.adaptiveGain,
  });

  // Convert profile to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'noiseThreshold': noiseThreshold,
      'decibelBoost': decibelBoost,
      'equalizer': equalizer,
      'compressionThreshold': compressionThreshold,
      'compressionRatio': compressionRatio,
      'noiseSuppressionEnabled': noiseSuppressionEnabled,
      'adaptiveGain': adaptiveGain,
    };
  }

  // Create profile from JSON
  factory AudioProfile.fromJson(Map<String, dynamic> json) {
    return AudioProfile(
      name: json['name'] as String,
      noiseThreshold: json['noiseThreshold'] as double,
      decibelBoost: json['decibelBoost'] as double,
      equalizer: List<double>.from(json['equalizer'] as List),
      compressionThreshold: json['compressionThreshold'] as double,
      compressionRatio: json['compressionRatio'] as double,
      noiseSuppressionEnabled: json['noiseSuppressionEnabled'] as bool,
      adaptiveGain: json['adaptiveGain'] as double,
    );
  }
}

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

  // Noise estimation variables
  List<double> _noiseFloor = List.filled(512, 0.005);
  bool _isCalibrating = false;
  int _calibrationFrames = 0;
  static const int _requiredCalibrationFrames = 10;

  // Audio statistics
  double _currentDecibel = 0.0;
  final StreamController<double> _decibelStreamCtrl =
      StreamController<double>.broadcast();

  // Profiles storage
  List<AudioProfile> _profiles = [];
  AudioProfile? _currentProfile;

  // Track volume value internally since FlutterSoundPlayer doesn't expose it
  double _currentVolume = 0.5; // Default to 50%

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
    // await FlutterSoundNoiseSuppressor.enable();
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

    // Initialize profiles
    await initProfiles();

    // Start with calibration
    startNoiseCalibration();

    _streamCtrl.stream.listen((data) async {
      // Convert to Float32List
      Float32List floatData = convertUint8ToFloat32(data);

      if (floatData.isNotEmpty) {
        // Calculate audio metrics before processing
        calculateDecibels(floatData);

        // Apply audio enhancements in sequence
        floatData = applyNoiseSuppression(floatData);
        floatData = applyEqualization(floatData);
        floatData = applyCompression(floatData);
        floatData = applyAdaptiveGain(floatData);

        // Basic amplification
        for (int i = 0; i < floatData.length; i++) {
          floatData[i] *= decibelBoost;
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
    _currentVolume = vol; // Store the volume value
    await _player.setVolume(vol);
  }

  Stream<Float32List> get waveStream => _waveStreamCtrl.stream;

  // Expose equalization bands for UI
  List<double> get equalizer => _equalizer;

  // Add getters for settings that need to be accessed
  double get compressionThreshold => _compressionThreshold;
  double get compressionRatio => _compressionRatio;
  double get adaptiveGain => _adaptiveGain;
  bool get isNoiseSuppressionEnabled => _noiseSuppressionEnabled;

  // Method to get volume (needed for settings screen)
  double getVolume() {
    // Return the tracked volume value
    return _currentVolume;
  }

  // Initialize with default profile
  Future<void> initProfiles() async {
    await loadProfiles();

    // If no profiles exist, create default ones
    if (_profiles.isEmpty) {
      _profiles = [
        AudioProfile(
          name: 'Default',
          noiseThreshold: noiseThreshold,
          decibelBoost: decibelBoost,
          equalizer: List.from(_equalizer),
          compressionThreshold: _compressionThreshold,
          compressionRatio: _compressionRatio,
          noiseSuppressionEnabled: _noiseSuppressionEnabled,
          adaptiveGain: _adaptiveGain,
        ),
        AudioProfile(
          name: 'Speech Focus',
          noiseThreshold: 0.02,
          decibelBoost: 1.5,
          equalizer: [1.8, 2.0, 2.2, 2.0, 1.8, 1.5, 1.2, 1.0, 0.7, 0.5],
          compressionThreshold: 0.4,
          compressionRatio: 2.5,
          noiseSuppressionEnabled: true,
          adaptiveGain: 1.8,
        ),
        AudioProfile(
          name: 'Music',
          noiseThreshold: 0.005,
          decibelBoost: 1.2,
          equalizer: [1.5, 1.3, 1.2, 1.0, 1.0, 1.0, 1.2, 1.3, 1.5, 1.7],
          compressionThreshold: 0.7,
          compressionRatio: 1.5,
          noiseSuppressionEnabled: false,
          adaptiveGain: 1.3,
        ),
      ];

      await saveProfiles();
    }

    // Apply the first profile by default
    if (_profiles.isNotEmpty) {
      await applyProfile(_profiles[0]);
    }
  }

  Future<void> loadProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString('audio_profiles');

      if (profilesJson != null) {
        final List<dynamic> decodedList = jsonDecode(profilesJson);
        _profiles =
            decodedList
                .map((profileMap) => AudioProfile.fromJson(profileMap))
                .toList();
      }

      // Load last used profile
      final lastProfileName = prefs.getString('last_profile');
      if (lastProfileName != null) {
        final lastProfile = _profiles.firstWhere(
          (p) => p.name == lastProfileName,
          orElse:
              () =>
                  _profiles.isNotEmpty
                      ? _profiles[0]
                      : AudioProfile(
                        name: 'Default',
                        noiseThreshold: 0.01,
                        decibelBoost: 1.0,
                        equalizer: List.filled(10, 1.0),
                        compressionThreshold: 0.5,
                        compressionRatio: 2.0,
                        noiseSuppressionEnabled: true,
                        adaptiveGain: 1.0,
                      ),
        );

        await applyProfile(lastProfile);
      }
    } catch (e) {
      print("Error loading profiles: $e");
    }
  }

  Future<void> saveProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = jsonEncode(
        _profiles.map((p) => p.toJson()).toList(),
      );
      await prefs.setString('audio_profiles', profilesJson);

      // Save current profile as last used
      if (_currentProfile != null) {
        await prefs.setString('last_profile', _currentProfile!.name);
      }
    } catch (e) {
      print("Error saving profiles: $e");
    }
  }

  Future<void> applyProfile(AudioProfile profile) async {
    noiseThreshold = profile.noiseThreshold;
    decibelBoost = profile.decibelBoost;
    _equalizer = List.from(profile.equalizer);
    _compressionThreshold = profile.compressionThreshold;
    _compressionRatio = profile.compressionRatio;
    await setNoiseSuppressionEnabled(profile.noiseSuppressionEnabled);
    _adaptiveGain = profile.adaptiveGain;

    _currentProfile = profile;

    // Save this as the last used profile
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_profile', profile.name);
  }

  Future<void> saveCurrentAsProfile(String name) async {
    final newProfile = AudioProfile(
      name: name,
      noiseThreshold: noiseThreshold,
      decibelBoost: decibelBoost,
      equalizer: List.from(_equalizer),
      compressionThreshold: _compressionThreshold,
      compressionRatio: _compressionRatio,
      noiseSuppressionEnabled: _noiseSuppressionEnabled,
      adaptiveGain: _adaptiveGain,
    );

    // Replace existing profile with same name or add new
    final existingIndex = _profiles.indexWhere((p) => p.name == name);
    if (existingIndex >= 0) {
      _profiles[existingIndex] = newProfile;
    } else {
      _profiles.add(newProfile);
    }

    _currentProfile = newProfile;
    await saveProfiles();
  }

  Future<void> deleteProfile(String name) async {
    _profiles.removeWhere((p) => p.name == name);
    await saveProfiles();
  }

  List<AudioProfile> get profiles => _profiles;
  AudioProfile? get currentProfile => _currentProfile;

  // Start noise floor calibration
  void startNoiseCalibration() {
    _isCalibrating = true;
    _calibrationFrames = 0;
    _noiseFloor = List.filled(512, 0.005);
  }

  // Enhanced noise suppression using spectral subtraction
  Float32List applyNoiseSuppression(Float32List audioData) {
    if (!_noiseSuppressionEnabled) return audioData;

    // Create result buffer
    final result = Float32List(audioData.length);

    // Basic time-domain noise gate
    for (int i = 0; i < audioData.length; i++) {
      if (audioData[i].abs() < noiseThreshold * 2) {
        result[i] = 0; // Suppress very low signals
      } else {
        // Soft noise reduction by subtracting estimated noise floor
        double signalStrength = audioData[i].abs() - noiseThreshold;
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
                magnitude - (_noiseFloor[i] * noiseThreshold * 10);
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
        print("Error in spectral noise reduction: $e");
        // We'll fall back to the simpler noise gate results
      }
    }

    return result;
  }

  // Calculate audio level in decibels
  void calculateDecibels(Float32List audioData) {
    if (audioData.isEmpty) return;

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

    // Send to stream
    _decibelStreamCtrl.add(_currentDecibel);
  }

  // Get current decibel level
  double get currentDecibel => _currentDecibel;

  // Stream of decibel measurements
  Stream<double> get decibelStream => _decibelStreamCtrl.stream;
}
