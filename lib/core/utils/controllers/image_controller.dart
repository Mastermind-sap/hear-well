import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

// Import our new Cloudinary service
import '../services/upload/cloudinary_service.dart';

class ImageController {
  /// Compresses an image from the given source
  static Future<Uint8List?> compressedImage({
    required ImageSource source,
    required int maxSize,
    required BuildContext context,
  }) async {
    try {
      // Pick image from source
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile == null) return null;
      
      // Read as bytes
      final Uint8List bytes = await pickedFile.readAsBytes();
      
      // If already small enough, return as is
      if (bytes.length <= maxSize) return bytes;
      
      // Create a temporary file to store the picked image
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);
      
      // Compress the image
      int quality = 90;
      Uint8List? compressedData;
      
      while (quality > 10) {
        compressedData = await FlutterImageCompress.compressWithFile(
          tempFile.path,
          quality: quality,
        );
        
        if (compressedData != null && compressedData.length <= maxSize) {
          break;
        }
        
        quality -= 10;
      }
      
      // Clean up the temp file
      await tempFile.delete();
      
      return compressedData;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
      return null;
    }
  }
  
  /// Uploads an image to Cloudinary and returns the download URL
  static Future<String?> uploadImage(Uint8List imageData, String path) async {
    return await CloudinaryService.uploadImage(imageData, path);
  }
  
  /// Uploads a profile image to Cloudinary
  static Future<String?> uploadProfileImage(Uint8List imageData, String userId) async {
    try {
      // Validate inputs
      if (userId.isEmpty) {
        debugPrint('Invalid user ID for profile image upload');
        return null;
      }
      
      if (imageData.isEmpty) {
        debugPrint('Empty image data for profile image upload');
        return null;
      }
      
      debugPrint('Uploading profile image for user: $userId');
      
      // Use Cloudinary service
      return await CloudinaryService.uploadProfileImage(imageData, userId);
    } catch (e) {
      debugPrint('Error in uploadProfileImage: $e');
      return null;
    }
  }
  
  /// Deletes an image from Cloudinary by URL
  static Future<bool> deleteImage(String imageUrl) async {
    return await CloudinaryService.deleteImage(imageUrl);
  }
  
  /// Fetches an image from Cloudinary by URL
  static Future<Uint8List?> fetchImage(String imageUrl) async {
    return await CloudinaryService.fetchImage(imageUrl);
  }
}
