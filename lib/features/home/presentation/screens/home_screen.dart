import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
    // _initializeSpeech();
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

  void _errorListener(SpeechRecognitionError error) async{
    print('Speech error: ${error.errorMsg}');
    await _startListening();
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
  Future<void> scanForAudioDevices() async {

    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.name.isNotEmpty) {
          print("Found Device: ${r.device.name}, ID: ${r.device.id}");
          if (r.advertisementData.serviceUuids.contains("0000110B-0000-1000-8000-00805F9B34FB")) {
            print("This is an audio output device.");
            connectToDevice(r.device);
          }
        }
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      print("Connected to ${device.name}");
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        print("Service: ${service.uuid}");
      }
    } catch (e) {
      print("Connection failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home",
        style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          )
      )),
      body: Center(child: Text(_transcription)),
    );
  }
}
