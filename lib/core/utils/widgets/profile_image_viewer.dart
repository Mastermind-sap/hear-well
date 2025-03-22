import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
// Add import for ImageController
import '../controllers/image_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// [imagePath] refers to a network image
/// [imageData] is for local data while editing
class ProfileImageViewer extends StatefulWidget {
  final double height;
  final String? imagePath;
  final Uint8List? imageData;
  final bool showBorder;
  final bool enabled;
  final void Function(Uint8List?)? onImageChange;
  final bool uploadImmediately; // Add this parameter
  
  const ProfileImageViewer({
    super.key,
    this.height = 150,
    this.imagePath,
    this.imageData,
    this.showBorder = false,
    this.enabled = true,
    this.onImageChange,
    this.uploadImmediately = true, // Default to true for backward compatibility
  });

  @override
  State<ProfileImageViewer> createState() => ProfileImageViewerState();
}

class ProfileImageViewerState extends State<ProfileImageViewer> {
  Uint8List? _image;
  ImagePicker picker = ImagePicker();
  String? _uploadedImageUrl;
  bool _isLoading = false;

  void updateImage(Uint8List? image) async {
    if (image != null) {
      setState(() {
        _image = image;
      });
      
      // Only upload immediately if explicitly requested
      if (widget.uploadImmediately) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final imageUrl = await ImageController.uploadProfileImage(image, user.uid);
          if (imageUrl != null && mounted) {
            setState(() {
              _uploadedImageUrl = imageUrl;
            });
          }
        }
      }
      
      if (widget.onImageChange != null) {
        widget.onImageChange!(image);
      }
    }
  }
  
  // Helper method to manually upload image after user creation
  Future<String?> uploadSelectedImage(String userId) async {
    if (_image != null) {
      final imageUrl = await ImageController.uploadProfileImage(_image!, userId);
      if (imageUrl != null && mounted) {
        setState(() {
          _uploadedImageUrl = imageUrl;
        });
      }
      return imageUrl;
    }
    return null;
  }

  Future<void> fetchImageFromUrl() async {
    if (_uploadedImageUrl != null && _image == null) {
      setState(() {
        _isLoading = true;
      });
      
      final fetchedImage = await ImageController.fetchImage(_uploadedImageUrl!);
      
      if (fetchedImage != null && mounted) {
        setState(() {
          _image = fetchedImage;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Uint8List?> pickImage(ImageSource imageSource) async {
    Uint8List? img = await ImageController.compressedImage(
      source: imageSource,
      maxSize: 1024 * 1024,
      context: context,
    );
    if (img != null && mounted) {
      Directory tempDir = await getTemporaryDirectory();
      File compressed = File("${tempDir.path}/compressed.jpg");
      await compressed.writeAsBytes(img);

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: compressed.path,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.blue,
              activeControlsWidgetColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              dimmedLayerColor: Colors.grey,
              lockAspectRatio: true),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );
      if (croppedFile != null) {
        img = await croppedFile.readAsBytes();
      }
      await compressed.delete(recursive: true);
    }
    return img;
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Library'),
                  onTap: () async {
                    updateImage(await pickImage(ImageSource.gallery));
                    if (mounted) Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  updateImage(await pickImage(ImageSource.camera));
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.imageData != null) {
      _image = widget.imageData;
    }
    _uploadedImageUrl = widget.imagePath;
    // Fetch image if URL is provided but no local data exists
    if (_uploadedImageUrl != null && _image == null) {
      fetchImageFromUrl();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => (widget.enabled) ? _showPicker(context) : null,
      child: CircleAvatar(
        backgroundColor: widget.showBorder
            ? const Color.fromRGBO(196, 196, 196, 1)
            : Colors.transparent,
        radius: widget.height / 2,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.height),
          clipBehavior: Clip.hardEdge,
          child: _isLoading
              ? const CircularProgressIndicator()
              : _image != null
                  ? Image.memory(
                      _image!,
                      fit: BoxFit.fitHeight,
                      height: widget.height,
                    )
                  : _uploadedImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: _uploadedImageUrl!,
                          fit: BoxFit.cover,
                          height: widget.height,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (BuildContext context, _, __) {
                            return Icon(
                              CupertinoIcons.person_alt_circle,
                              size: widget.height,
                            );
                          },
                        )
                      : Icon(
                          CupertinoIcons.person_alt_circle,
                          size: widget.height,
                        ),
        ),
      ),
    );
  }
}