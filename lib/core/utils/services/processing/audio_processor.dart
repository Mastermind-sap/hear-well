import 'dart:isolate';
import 'dart:typed_data';

// import 'pre_processing.dart';
// import 'noise_reduction.dart';
// import 'post_processing.dart';
import 'dtln_model_service.dart';

void audioProcessingIsolate(SendPort mainSendPort) {
  final ReceivePort isolateReceivePort = ReceivePort();
  mainSendPort.send(isolateReceivePort.sendPort);

  isolateReceivePort.listen((dynamic message) async {
    if (message is Uint8List) {
      final ns = await NoiseSuppressor.create(
        'model_quant_1.tflite',
        'model_quant_2.tflite',
      );

      try {
        final Float32List audioFloat32 = message.buffer.asFloat32List();
        final Float32List enhanced128 = ns.processFrame(audioFloat32);

        // final Uint8List pre = preProcessAudio(message);
        // final Uint8List enhOutput = await ;
        // final Uint8List post = postProcessAudio(denoised);

        mainSendPort.send(enhanced128);
        ns.resetStates();
      } catch (e) {
        print('[AudioProcessor] Error: $e');
        ns.close();
      }
    }
  });
}
