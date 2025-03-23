import 'dart:async';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TranscriptionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final StreamController<String> transcriptionStreamController =
      StreamController<String>.broadcast();
  Future<void> initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: _statusListener,
      onError: _errorListener,
      finalTimeout: Duration(seconds: 10),
    );
    if (available) {
      await _startListening();
    }
  }

  void _statusListener(String status) async {
    print("Status: $status");
    if (status == 'done') {
      await _startListening();
    } else if (status == 'notListening') {
      await _startListening();
    }
  }

  void _errorListener(SpeechRecognitionError error) {
    print('Speech error: ${error.errorMsg}');
  }

  void _onResult(SpeechRecognitionResult result) {
    print("result: ${result.recognizedWords}");
    transcriptionStreamController.add(result.recognizedWords);
  }

  Future<void> _startListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      await _speech.listen(onResult: _onResult);
    } catch (e) {
      print('Error starting speech recognition: $e');
      // Try to recover by restarting after delay
      Future.delayed(const Duration(seconds: 2), () async {
        await initializeSpeech();
      });
    }
  }
  void stopListening() {
    _speech.stop();
  }

  void dispose() {
    transcriptionStreamController.close();
    _speech.stop();
  }
}
