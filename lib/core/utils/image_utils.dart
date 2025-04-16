import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageUtils {
  // Calculate size reduction percentage
  static double calculateSizeReduction(int originalSize, int compressedSize) {
    return ((originalSize - compressedSize) / originalSize) * 100;
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      double kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else {
      double mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    }
  }

  // Get file extension
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  // Compress an image
  static Future<File?> compressImage({
    required File file,
    required int quality,
    int? minWidth,
    int? minHeight,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final extension = getFileExtension(file.path);
      final targetPath = path.join(
        tempDir.path,
        '${DateTime.now().millisecondsSinceEpoch}$extension',
      );
      
      // Choose the format based on the extension
      CompressFormat format;
      switch (extension) {
        case '.jpg':
        case '.jpeg':
          format = CompressFormat.jpeg;
          break;
        case '.png':
          format = CompressFormat.png;
          break;
        case '.heic':
          format = CompressFormat.heic;
          break;
        default:
          format = CompressFormat.jpeg;
      }
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth ?? 1080, // Default reasonable width
        minHeight: minHeight ?? 1920, // Default reasonable height
        format: format,
      );
      
      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }
}