import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/foundation.dart';

import 'audio/models/audio_profile.dart';
import 'audio/processors/audio_processor.dart';
import 'audio/utils/audio_utils.dart';
import 'audio/background/audio_background_service.dart';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final StreamController<Uint8List> _streamCtrl = StreamController<Uint8List>();
  final StreamController<Float32List> _waveStreamCtrl =
      StreamController<Float32List>.broadcast();
  final StreamController<double> _decibelStreamCtrl =
      StreamController<double>.broadcast();

  static const int sampleRate = 96000;
  static const int numOfChannels = 2;
  static const int bitRate = 96000;
  static bool isProcessing = false;

  // Components
  final AudioProcessor _processor = AudioProcessor();
  final ProfileManager _profileManager = ProfileManager();
  final AudioBackgroundService _backgroundService = AudioBackgroundService();

  // Track volume value internally since FlutterSoundPlayer doesn't expose it
  double _currentVolume = 0.5; // Default to 50%
  bool _isRunning = false;

  // Initialization
  Future<void> initialize() async {
    // Initialize background service
    await _backgroundService.initializeService();
    await _profileManager.loadProfiles();

    // Initialize profiles
    await initProfiles();

    // Listen for audio stats from background service
    _backgroundService.onAudioStats.listen((stats) {
      if (stats != null && stats.containsKey('decibel')) {
        _decibelStreamCtrl.add(stats['decibel']);
      }
    });
  }

  // Start audio processing
  Future<void> startLivePlayback() async {
    if (_isRunning) return;
    _isRunning = true;

    await _recorder.openRecorder();
    await _player.openPlayer();

    try {
      await _player.setVolume(_currentVolume);
    } catch (e) {
      debugPrint("Error setting volume: $e");
    }

    // Set higher buffer size for better background operation
    await _player.startPlayerFromStream(
      codec: Codec.pcmFloat32,
      sampleRate: sampleRate,
      numChannels: numOfChannels,
      interleaved: true,
      bufferSize: 1024,
    );

    // Start with noise calibration
    // _processor.startNoiseCalibration();

    _streamCtrl.stream.listen((data) async {
      // Convert to Float32List
      Float32List floatData = AudioUtils.convertUint8ToFloat32(data);

      if (floatData.isNotEmpty) {
        // Process audio
        floatData = _processor.processAudio(floatData);

        // Send audio stats to background service for persistence
        _backgroundService.sendAudioStats({
          'decibel': _processor.currentDecibel,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // Send current decibel level
        _decibelStreamCtrl.add(_processor.currentDecibel);

        // Convert back to Uint8List for playback
        final processedData = AudioUtils.convertFloat32ToUint8(floatData);
        if (isProcessing) {
          _player.feedUint8FromStream(processedData);
        } else {
          _player.feedUint8FromStream(data);
        }
        // Update waveform visualization
        _waveStreamCtrl.add(floatData);
      } else {
        // If conversion failed, use the original data
        await _player.feedUint8FromStream(data);
      }
    });

    await _recorder.startRecorder(
      codec: Codec.pcmFloat32,
      sampleRate: sampleRate,
      bitRate: bitRate,
      numChannels: numOfChannels,
      audioSource: AudioSource.defaultSource,
      toStream: _streamCtrl.sink,
    );

    // Start the background service
    _backgroundService.startBackgroundService();
  }

  // Stop audio processing
  Future<void> stopLivePlayback() async {
    if (!_isRunning) return;
    _isRunning = false;

    // Stop background service
    _backgroundService.stopBackgroundService();

    await _recorder.stopRecorder();
    await _player.stopPlayer();
  }

  // Volume control
  Future<void> setVolume(double vol) async {
    debugPrint("Setting volume to $vol");
    _currentVolume = vol; // Store the volume value
    await _player.setVolume(vol);
  }

  double getVolume() {
    return _currentVolume;
  }

  // Audio processing settings
  void setNoiseThreshold(double threshold) {
    _processor.setNoiseThreshold(threshold);
  }

  void setDecibelBoost(double boost) {
    _processor.setDecibelBoost(boost);
  }

  void setEqualizer(List<double> bands) {
    _processor.setEqualizer(bands);
  }

  void setCompression(double threshold, double ratio) {
    _processor.setCompression(threshold, ratio);
  }

  Future<void> setNoiseSuppressionEnabled(bool enabled) async {
    await _processor.setNoiseSuppressionEnabled(enabled);
  }

  void setAdaptiveGain(double gain) {
    _processor.setAdaptiveGain(gain);
  }

  void startNoiseCalibration() {
    _processor.startNoiseCalibration();
  }

  // Profile management
  Future<void> initProfiles() async {
    await _profileManager.loadProfiles();

    // If no profiles exist, create default ones
    if (_profileManager.profiles.isEmpty) {
      _profileManager.profile = ProfileManager.getDefaultProfiles(
        noiseThreshold: _processor.noiseThreshold,
        decibelBoost: _processor.decibelBoost,
        equalizer: _processor.equalizer,
        compressionThreshold: _processor.compressionThreshold,
        compressionRatio: _processor.compressionRatio,
        noiseSuppressionEnabled: _processor.isNoiseSuppressionEnabled,
        adaptiveGain: _processor.adaptiveGain,
      );

      await _profileManager.saveProfiles();
    }

    // Apply the first profile by default
    if (_profileManager.profiles.isNotEmpty) {
      await applyProfile(_profileManager.profiles[0]);
    }
  }

  Future<void> applyProfile(AudioProfile profile) async {
    _processor.setNoiseThreshold(profile.noiseThreshold);
    _processor.setDecibelBoost(profile.decibelBoost);
    _processor.setEqualizer(List.from(profile.equalizer));
    _processor.setCompression(
      profile.compressionThreshold,
      profile.compressionRatio,
    );
    await _processor.setNoiseSuppressionEnabled(
      profile.noiseSuppressionEnabled,
    );
    _processor.setAdaptiveGain(profile.adaptiveGain);

    _profileManager.setCurrentProfile(profile);

    // Save this as the last used profile
    await _profileManager.saveProfiles();
  }

  Future<void> saveCurrentAsProfile(String name) async {
    final newProfile = AudioProfile(
      name: name,
      noiseThreshold: _processor.noiseThreshold,
      decibelBoost: _processor.decibelBoost,
      equalizer: List.from(_processor.equalizer),
      compressionThreshold: _processor.compressionThreshold,
      compressionRatio: _processor.compressionRatio,
      noiseSuppressionEnabled: _processor.isNoiseSuppressionEnabled,
      adaptiveGain: _processor.adaptiveGain,
    );

    _profileManager.saveProfile(newProfile);
    await _profileManager.saveProfiles();
  }

  Future<void> deleteProfile(String name) async {
    _profileManager.deleteProfile(name);
    await _profileManager.saveProfiles();
  }

  // Expose streams and data
  Stream<Float32List> get waveStream => _waveStreamCtrl.stream;
  Stream<double> get decibelStream => _decibelStreamCtrl.stream;
  double get currentDecibel => _processor.currentDecibel;

  // Expose settings for UI
  double get noiseThreshold => _processor.noiseThreshold;
  double get decibelBoost => _processor.decibelBoost;
  List<double> get equalizer => _processor.equalizer;
  double get compressionThreshold => _processor.compressionThreshold;
  double get compressionRatio => _processor.compressionRatio;
  bool get isNoiseSuppressionEnabled => _processor.isNoiseSuppressionEnabled;
  double get adaptiveGain => _processor.adaptiveGain;

  // Expose profiles
  List<AudioProfile> get profiles => _profileManager.profiles;
  AudioProfile? get currentProfile => _profileManager.currentProfile;
}
