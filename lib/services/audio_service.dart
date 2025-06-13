import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Added for EventChannel

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

  static const int sampleRate = 96000; // This is for flutter_sound
  static const int numOfChannels = 2; // This is for flutter_sound
  static const int bitRate = 96000; // This is for flutter_sound
  static bool isProcessing = false;

  // Components
  final AudioProcessor _processor = AudioProcessor();
  final ProfileManager _profileManager = ProfileManager();
  final AudioBackgroundService _backgroundService = AudioBackgroundService();

  double _currentVolume = 0.5;
  bool _isRunning = false; // Tracks flutter_sound based playback

  // --- New additions for Native Audio Stream Listening ---
  static const EventChannel _nativeAudioStreamChannel = EventChannel('com.example.hear_well/audio_stream');
  StreamSubscription? _nativeAudioSubscription;
  final List<Uint8List> _nativeAudioBuffer = []; // Buffer for raw native audio frames
  bool _isListeningToNativeStream = false;

  // StreamController to broadcast the raw native audio frames
  final StreamController<Uint8List> _nativeAudioFrameController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get nativeAudioFrameStream => _nativeAudioFrameController.stream;

  bool get isListeningToNativeStream => _isListeningToNativeStream;
  // --- End of new additions ---

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

  // --- Methods for Native Audio Stream ---
  Future<void> startListeningToNativeStream() async {
    if (_isListeningToNativeStream) {
      debugPrint("AudioService: Already listening to native audio stream.");
      return;
    }
    // Ensure flutter_sound based loopback is stopped if it was running
    if (_isRunning) {
      await stopLivePlayback();
    }

    debugPrint("AudioService: Starting to listen to native audio stream.");
    try {
      _nativeAudioSubscription = _nativeAudioStreamChannel.receiveBroadcastStream().listen(
        (dynamic data) {
          if (data is Uint8List) {
            _nativeAudioBuffer.add(data);
            _nativeAudioFrameController.add(data); // Send the latest frame
            // debugPrint("AudioService: Native audio frame received. Buffer size: ${_nativeAudioBuffer.length}");
            if (_nativeAudioBuffer.length > 200) { // Limit buffer size
              _nativeAudioBuffer.removeAt(0);
            }
          } else if (data is List) {
            try {
              final Uint8List frame = Uint8List.fromList(data.cast<int>());
              _nativeAudioBuffer.add(frame);
              _nativeAudioFrameController.add(frame);
              if (_nativeAudioBuffer.length > 200) {
                _nativeAudioBuffer.removeAt(0);
              }
            } catch (e) {
              debugPrint("AudioService: Error converting List to Uint8List: $e");
            }
          } else if (data != null) {
            debugPrint("AudioService: Received unexpected data type from native stream: ${data.runtimeType}");
          }
        },
        onError: (dynamic error) {
          debugPrint("AudioService: Error on native audio stream: $error");
          stopListeningToNativeStream();
        },
        onDone: () {
          debugPrint("AudioService: Native audio stream completed.");
          _isListeningToNativeStream = false;
        },
        cancelOnError: true,
      );
      _isListeningToNativeStream = true;
      debugPrint("AudioService: Successfully subscribed to native audio stream.");
    } catch (e) {
      debugPrint("AudioService: Failed to start listening to native audio stream: $e");
      _isListeningToNativeStream = false;
    }
  }

  Future<void> stopListeningToNativeStream() async {
    if (!_isListeningToNativeStream && _nativeAudioSubscription == null) {
      debugPrint("AudioService: Not currently listening to native stream or subscription is null.");
      return;
    }
    debugPrint("AudioService: Stopping listening to native audio stream.");
    try {
      await _nativeAudioSubscription?.cancel();
    } catch (e) {
      debugPrint("AudioService: Error cancelling native audio subscription: $e");
    }
    _nativeAudioSubscription = null;
    _nativeAudioBuffer.clear();
    _isListeningToNativeStream = false;
    debugPrint("AudioService: Stopped listening to native audio stream.");
  }

  List<Uint8List> getBufferedNativeAudio() {
    return List.from(_nativeAudioBuffer);
  }

  void clearNativeAudioBuffer() {
    _nativeAudioBuffer.clear();
  }
  // --- End of Methods for Native Audio Stream ---

  // Start audio processing
  Future<void> startLivePlayback() async {
    if (_isRunning) return;
    // Ensure native loopback is stopped if it was running
    if (_isListeningToNativeStream) {
      await stopListeningToNativeStream(); // And potentially call platform.invokeMethod('stopAudioLoopback') from UI
    }
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

  // Dispose method to clean up resources
  void dispose() {
    debugPrint("AudioService: Disposing...");
    _recorder.closeRecorder();
    _player.closePlayer();
    _streamCtrl.close();
    _waveStreamCtrl.close();
    _decibelStreamCtrl.close();
    // --- New: Clean up native stream resources ---
    stopListeningToNativeStream();
    _nativeAudioFrameController.close();
    // --- End of new --- 
    debugPrint("AudioService: Disposed all resources.");
  }
}
