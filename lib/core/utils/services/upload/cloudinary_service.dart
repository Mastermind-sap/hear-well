import 'dart:convert';
import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CloudinaryService {
  // Update with your Cloudinary credentials
  static const String cloudName = 'defzndpsh'; 
  static const String uploadPreset = 'ml_default';
  
  // Direct HTTP upload method as fallback
  static Future<String?> uploadImageDirectHttp(Uint8List imageData, String folder) async {
    try {
      if (imageData.isEmpty) {
        debugPrint('Cannot upload empty image data');
        return null;
      }
      
      // Create a multipart request
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Generate a unique file name
      final String fileName = '${const Uuid().v4()}.jpg';
      
      // Add the upload preset and folder
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      
      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageData);
      
      // Add the file to the request
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName,
      ));
      
      debugPrint('Sending direct HTTP request to Cloudinary...');
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Clean up temp file
      await file.delete();
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String secureUrl = data['secure_url'];
        debugPrint('Direct upload successful. URL: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('Direct upload failed. Status: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error in direct HTTP upload: $e');
      return null;
    }
  }

  /// Uploads an image to Cloudinary and returns the URL
  static Future<String?> uploadImage(Uint8List imageData, String folder) async {
    // Try SDK method first
    try {
      if (imageData.isEmpty) {
        debugPrint('Cannot upload empty image data');
        return null;
      }
      
      debugPrint('Uploading image to Cloudinary folder: $folder');
      
      // Add more details about the upload being attempted
      debugPrint('Using cloud name: $cloudName, upload preset: $uploadPreset');
      
      // Generate a unique identifier for the file
      final String fileIdentifier = const Uuid().v4();
      
      // Create a temporary file to handle the upload
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/$fileIdentifier.jpg';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(imageData);
      
      debugPrint('Temp file created at: ${tempFile.path}, Size: ${await tempFile.length()} bytes');
      
      try {
        // Initialize CloudinaryPublic with debug mode
        final cloudinary = CloudinaryPublic(
          cloudName,
          uploadPreset,
          cache: false,
        );
        
        // Use CloudinaryFile.fromFile which accepts a File object
        final CloudinaryFile cloudFile = CloudinaryFile.fromFile(
          tempFile.path,
          folder: folder,
        );
        
        debugPrint('Starting Cloudinary upload via SDK...');
        final CloudinaryResponse response = await cloudinary.uploadFile(cloudFile);
        
        await tempFile.delete();
        
        debugPrint('Image successfully uploaded. URL: ${response.secureUrl}');
        return response.secureUrl;
      } catch (uploadError) {
        debugPrint('Cloudinary SDK upload error: $uploadError');
        
        // Clean up
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        
        // Fallback to direct HTTP method
        debugPrint('Trying direct HTTP upload method as fallback...');
        return await uploadImageDirectHttp(imageData, folder);
      }
    } catch (e) {
      debugPrint('Error in Cloudinary upload: $e');
      
      // Fallback to direct HTTP method
      return await uploadImageDirectHttp(imageData, folder);
    }
  }
  
  /// Uploads a profile image to Cloudinary
  static Future<String?> uploadProfileImage(Uint8List imageData, String userId) async {
    return await uploadImage(imageData, 'profiles/$userId');
  }
  
  /// Deletes an image from Cloudinary by URL
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract the public ID from the URL
      final Uri uri = Uri.parse(imageUrl);
      final String pathWithoutExtension = uri.path.substring(
        uri.path.lastIndexOf('/') + 1, 
        uri.path.lastIndexOf('.')
      );
      
      // Unfortunately, Cloudinary API requires API key and secret for deletion
      // which should not be in client-side code
      // This would typically be handled through a server endpoint
      debugPrint('Cannot delete image directly from client side. Public ID: $pathWithoutExtension');
      
      return false;
    } catch (e) {
      debugPrint('Error parsing Cloudinary URL: $e');
      return false;
    }
  }
  
  /// Fetches an image from Cloudinary by URL
  static Future<Uint8List?> fetchImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        debugPrint('Empty image URL provided');
        return null;
      }
      
      // Fetch the image using HTTP
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('Failed to fetch image. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching image from Cloudinary: $e');
      return null;
    }
  }
}
