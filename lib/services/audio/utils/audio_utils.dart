import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class AudioUtils {
  // Custom conversion from Uint8List to Float32List
  static Float32List convertUint8ToFloat32(Uint8List uint8Data) {
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
      debugPrint("Error converting Uint8List to Float32List: $e");
      return Float32List(0);
    }
  }

  // Custom conversion from Float32List to Uint8List
  static Uint8List convertFloat32ToUint8(Float32List floatData) {
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
      debugPrint("Error converting Float32List to Uint8List: $e");
      return Uint8List(0);
    }
  }
}
