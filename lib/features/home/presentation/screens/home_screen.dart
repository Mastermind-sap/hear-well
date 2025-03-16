import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _transcription = '';
  late SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _setupBluetooth();
  }

  Future<void> _initializeSpeech() async {
    _speech = SpeechToText();
    bool available = await _speech.initialize(
      onStatus: _statusListener,
      onError: _errorListener,
    );
    if (available) {
      await _startListening();
    }
  }

  void _statusListener(String status) async {
    if (status == 'done') {
      await _startListening();
    }
  }

  void _errorListener(SpeechRecognitionError error) {
    print('Speech error: ${error.errorMsg}');
  }

  void _onResult(SpeechRecognitionResult result) {
    setState(() {
      _transcription = result.recognizedWords;
    });
  }

  Future<void> _startListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    await _speech.listen(
      onResult: _onResult,
    );
  }

  void _setupBluetooth() {
    // 3) Stream processed audio to Bluetooth earbuds (placeholder).
    // 4) Convert audio to text is done in the above method.
    // ...implementation details...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(child: Text(_transcription)),
    );
  }
}
