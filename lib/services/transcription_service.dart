import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

class TranscriptionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final StreamController<String> _transcriptionStreamController =
      StreamController<String>.broadcast();

  bool _isListening = false;
  String _lastRecognizedWords = '';
  String _currentTranscript = '';

  // Initialize the speech recognition
  Future<bool> initialize() async {
    final bool available = await _speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );

    return available;
  }

  // Start listening for speech
  Future<void> startListening() async {
    if (!_isListening) {
      if (!_speech.isAvailable) {
        bool available = await initialize();
        if (!available) {
          _transcriptionStreamController.add(
            "Error: Speech recognition not available",
          );
          return;
        }
      }

      _isListening = true;
      _currentTranscript = '';

      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: Duration(minutes: 5), // Listen for longer periods
        pauseFor: Duration(seconds: 5), // Pause after silence
        partialResults: true, // Get partial results for real-time updates
        localeId: 'en_US', // Set locale - can be made configurable
      );

      _transcriptionStreamController.add("Listening...");
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      _transcriptionStreamController.add(_currentTranscript);
    }
  }

  // Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      _lastRecognizedWords = result.recognizedWords;
      _currentTranscript += ' ${result.recognizedWords}';
    }

    // Always send the current transcript (partial or final)
    _transcriptionStreamController.add(
      result.finalResult
          ? _currentTranscript
          : "Hearing: ${result.recognizedWords}",
    );
  }

  // Access to the transcription stream
  Stream<String> get transcriptionStream =>
      _transcriptionStreamController.stream;

  // Get the last recognized words
  String get lastRecognizedWords => _lastRecognizedWords;

  // Check if the service is listening
  bool get isListening => _isListening;

  // Legacy method for compatibility
  Future<String> transcribeAudio(String filePath) async {
    // This is just for backward compatibility
    await Future.delayed(const Duration(milliseconds: 500));
    return _lastRecognizedWords.isEmpty
        ? "No transcription available."
        : _lastRecognizedWords;
  }

  // Clean up resources
  void dispose() {
    _speech.stop();
    _transcriptionStreamController.close();
  }
}
