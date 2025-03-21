import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

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

  void setNoiseThreshold(double threshold) {
    noiseThreshold = threshold;
  }

  void setDecibelBoost(double boost) {
    decibelBoost = boost;
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
      await _player.feedUint8FromStream(data);

      // Convert to Float32 for waveform
      final List<Uint8List> buffers = [data];
      final floats = _helper.uint8ListToFloat32List(buffers);
      // Send the first Float32List if available
      if (floats.isNotEmpty) {
        final Float32List floatData = floats.first;
        for (int i = 0; i < floatData.length; i++) {
          if (floatData[i].abs() < noiseThreshold) {
            floatData[i] = 0;
          } else {
            floatData[i] *= decibelBoost;
          }
        }
        _waveStreamCtrl.add(floatData);
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

  Future<void> stopLivePlayback() async {
    await _recorder.stopRecorder();
    await _player.stopPlayer();
  }

  void setVolume(double vol) async {
    print("Setting volume to $vol");
    await _player.setVolume(vol);
  }

  Stream<Float32List> get waveStream => _waveStreamCtrl.stream;
}
