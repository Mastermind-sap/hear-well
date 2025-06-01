import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:fftea/fftea.dart';

/// Noise suppressor using a DTLN-style dual-stage TFLite model.
class NoiseSuppressor {
  final Interpreter _interpreter1;
  final Interpreter _interpreter2;
  // LSTM states for model1 and model2: shape [1,2,128,2] each.
  List<List<List<List<double>>>> _state1;
  List<List<List<List<double>>>> _state2;
  // Overlap buffer (last 384 samples of previous output)
  Float32List _overlapBuf = Float32List(512);

  // FFT objects (reuse for efficiency)
  final FFT _fft512 = FFT(512);
  final FFT _ifft512 = FFT(512);

  /// Private constructor.
  NoiseSuppressor._(this._interpreter1, this._interpreter2)
      : _state1 = [ List.generate(2, (_) => List.generate(128, (_) => [0.0, 0.0])) ],
        _state2 = [ List.generate(2, (_) => List.generate(128, (_) => [0.0, 0.0])) ];

  /// Factory to load models (from assets) and initialize states.
  static Future<NoiseSuppressor> create(String modelPath1, String modelPath2) async {
    // Load the TFLite models (ensure models are in pubspec assets).
    final interpreter1 = await Interpreter.fromAsset(modelPath1);
    final interpreter2 = await Interpreter.fromAsset(modelPath2);
    return NoiseSuppressor._(interpreter1, interpreter2);
  }

  /// Reset internal LSTM states to zero.
  void resetStates() {
    _state1 = [ List.generate(2, (_) => List.generate(128, (_) => [0.0, 0.0])) ];
    _state2 = [ List.generate(2, (_) => List.generate(128, (_) => [0.0, 0.0])) ];
    _overlapBuf.fillRange(0, 512, 0.0);
  }

  /// Processes a 512-sample block of audio (Float32List) and returns 128 enhanced samples.
  /// Uses overlap-add with hop size 128.
  Float32List processFrame(Float32List inputBlock) {
    // 1) FFT of input block (real-valued, 512 points) => complex spectrum.
    // Convert input to double list for FFT.
    final inputDouble = List<double>.from(inputBlock);
    final complexSpectrum = _fft512.realFft(inputDouble);
    // 2) Keep first 257 bins (DC..Nyquist), discard conjugates:contentReference[oaicite:4]{index=4}.
    final halfSpectrum = complexSpectrum.discardConjugates(); // Float64x2List of length 257
    // 3) Get magnitudes (Float64List of length 257).
    final magnitudes = halfSpectrum.magnitudes();
    // Prepare input for model1: shape [1,1,257].
    List<List<List<double>>> magInput = [ [ magnitudes.toList() ] ];

    // Prepare state1 input: shape [1,2,128,2] (List of shape).
    var statesInput1 = _state1;

    // 4) Stage-1 inference to get spectral mask and new state.
    var maskOutput = [ [ List<double>.filled(257, 0.0) ] ]; // [1,1,257]
    var newState1 = [ List.generate(2, (_) => List.generate(128, (_) => [0.0, 0.0])) ];
    _interpreter1.runForMultipleInputs(
      [magInput, statesInput1],
      {0: maskOutput, 1: newState1},
    );
    // Update mask and state.
    List<double> mask = maskOutput[0][0];
    _state1 = newState1;

    // 5) Apply mask: multiply complex spectrum (0..256) by mask.
    // Build full 512-point spectrum for IFFT (Hermitian symmetry).
    Float64x2List fullSpectrum = Float64x2List(512);
    for (int i = 0; i < 257; i++) {
      // masked complex = original * mask
      final orig = halfSpectrum[i];
      fullSpectrum[i] = Float64x2(orig.x * mask[i], orig.y * mask[i]);
    }
    // Reconstruct negative frequencies (i=1..255 mirrored).
    for (int i = 1; i < 256; i++) {
      // conjugate symmetry: index 512-i = conj(fullSpectrum[i])
      fullSpectrum[512 - i] =
          Float64x2(fullSpectrum[i].x, -fullSpectrum[i].y);
    }
    // Nyquist (i=256) and DC (i=0) are real so already set.

    // 6) Inverse FFT: complex to real. Use FFT forward on conjugate and scale (IDFT):contentReference[oaicite:5]{index=5}.
    // IDFT algorithm: x[n] = conj(FFT(conj(X[k])))/N
    Float64x2List conjFreq = Float64x2List.fromList(fullSpectrum.toList());
    for (int i = 0; i < 512; i++) {
      conjFreq[i] = Float64x2(conjFreq[i].x, -conjFreq[i].y);
    }
    _ifft512.inPlaceFft(conjFreq); // inPlaceFft modifies conjFreq and returns void.
    // Extract real time-domain block (divide by N).
    // After the inPlaceFft call, conjFreq holds the result of FFT(conj(X[k])).
    // The IDFT algorithm is x[n] = conj(FFT(conj(X[k])))/N.
    // The real part of x[n] is Re(FFT(conj(X[k])))/N, which is conjFreq[i].x / N.
    Float32List stage1Time = Float32List(512);
    for (int i = 0; i < 512; i++) {
      stage1Time[i] = (conjFreq[i].x / 512.0).toDouble();
    }

    // 7) Stage-2 inference: feed time-domain block and state2.
    List<List<List<double>>> timeInput = [ [ List<double>.from(stage1Time) ] ]; // [1,1,512]
    var statesInput2 = _state2;
    var enhOutput = [ List<double>.filled(512, 0.0) ]; // [1,512] (or [1,1,512])
    var newState2 = [ List.generate(2, (_) => List.generate(128, (_) => [0.0, 0.0])) ];
    _interpreter2.runForMultipleInputs(
      [timeInput, statesInput2],
      {0: enhOutput, 1: newState2},
    );
    // Extract enhanced block and update state2.
    List<double> enhancedBlock = enhOutput[0];
    _state2 = newState2;

    // 8) Overlap-add: add saved overlap (first 384 samples) to enhancedBlock.
    Float32List outputFrame = Float32List(128);
    for (int i = 0; i < 128; i++) {
      // Overlap: add previous buffer tail to current head.
      double prev = _overlapBuf[i];
      outputFrame[i] = (enhancedBlock[i] + prev).toDouble();
    }
    // Update overlap buffer: copy last 384 samples of enhancedBlock.
    for (int i = 0; i < 384; i++) {
      _overlapBuf[i] = i + 128 < 512
          ? enhancedBlock[i + 128].toDouble()
          : 0.0; // safety check
    }
    // Fill the rest with zero (not strictly needed beyond 384).
    for (int i = 384; i < 512; i++) {
      _overlapBuf[i] = 0.0;
    }

    // Return the 128-sample enhanced audio (Float32List).
    return outputFrame;
  }

  /// Clean up interpreters.
  void close() {
    _interpreter1.close();
    _interpreter2.close();
  }
}
