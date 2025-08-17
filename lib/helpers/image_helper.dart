import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  // Pick multiple images from gallery or camera
  static Future<List<String>> pickImages({
    required BuildContext context,
    int maxImages = 5,
  }) async {
    try {
      final List<String> imagePaths = [];

      // Show source selection dialog
      final ImageSource? source = await _showImageSourceDialog(context);
      if (source == null) return [];

      if (source == ImageSource.gallery) {
        // Pick multiple images from gallery
        final List<XFile> images = await _picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (images.length > maxImages) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Maximum $maxImages images allowed. Selected first $maxImages.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        // Take only the maximum allowed images
        final selectedImages = images.take(maxImages).toList();

        for (final image in selectedImages) {
          final savedPath = await _saveImageToAppDirectory(image);
          if (savedPath != null) {
            imagePaths.add(savedPath);
          }
        }
      } else {
        // Take photo with camera
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (image != null) {
          final savedPath = await _saveImageToAppDirectory(image);
          if (savedPath != null) {
            imagePaths.add(savedPath);
          }
        }
      }

      return imagePaths;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  // Show dialog to choose image source
  static Future<ImageSource?> _showImageSourceDialog(
    BuildContext context,
  ) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: const Text('Choose where to get the images from:'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Save image to app's document directory
  static Future<String?> _saveImageToAppDirectory(XFile image) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'location_images');

      // Create images directory if it doesn't exist
      final Directory imagesDirObj = Directory(imagesDir);
      if (!await imagesDirObj.exists()) {
        await imagesDirObj.create(recursive: true);
      }

      // Generate unique filename with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(image.path);
      final String fileName = 'location_$timestamp$extension';
      final String savedPath = path.join(imagesDir, fileName);

      // Copy image to app directory
      final File imageFile = File(image.path);
      await imageFile.copy(savedPath);

      return savedPath;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  // Get image widget from local path
  static Widget getImageWidget(
    String imagePath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    Widget imageWidget;

    // Check if it's a URL or local path
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Network image
      imageWidget = Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _getErrorPlaceholder(width, height);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _getLoadingPlaceholder(width, height);
        },
      );
    } else {
      // Local file
      final File imageFile = File(imagePath);
      if (imageFile.existsSync()) {
        imageWidget = Image.file(
          imageFile,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _getErrorPlaceholder(width, height);
          },
        );
      } else {
        imageWidget = _getErrorPlaceholder(width, height);
      }
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: imageWidget);
    }

    return imageWidget;
  }

  // Error placeholder widget
  static Widget _getErrorPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              color: Colors.grey[500],
              size: (height != null && height < 100) ? 24 : 40,
            ),
            if (height == null || height >= 60)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Image not found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Loading placeholder widget
  static Widget _getLoadingPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2),
      ),
    );
  }

  // Delete image from local storage
  static Future<bool> deleteImage(String imagePath) async {
    try {
      // Only delete local files, not network URLs
      if (!imagePath.startsWith('http://') &&
          !imagePath.startsWith('https://')) {
        final File imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Get app images directory size (for cleanup purposes)
  static Future<int> getImagesDirectorySize() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'location_images');
      final Directory imagesDirObj = Directory(imagesDir);

      if (!await imagesDirObj.exists()) return 0;

      int totalSize = 0;
      await for (final FileSystemEntity entity in imagesDirObj.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Pick a single image for profile picture
  static Future<String?> pickSingleImage({
    required BuildContext context,
  }) async {
    try {
      // Show source selection dialog
      final ImageSource? source = await _showImageSourceDialog(context);
      if (source == null) return null;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (image == null) return null;

      // Save the image to app's documents directory
      final String? savedPath = await _saveImageToAppDirectory(image);

      return savedPath;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}
