import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:photoshrink/core/utils/image_utils.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:photoshrink/data/models/compression_result.dart';

abstract class CompressionService {
  Future<CompressionResult?> compressImage({
    required String imagePath,
    required int quality,
  });
  
  Future<List<CompressionResult>> compressBatch({
    required List<String> imagePaths,
    required int quality,
  });
  
  Future<File?> saveCompressedImage({
    required File compressedImage,
    String? customName,
  });
}

class CompressionServiceImpl implements CompressionService {
  static const String TAG = 'CompressionService';
  
  CompressionServiceImpl() {
    LoggerUtil.i(TAG, 'CompressionService initialized');
  }
  
  @override
  Future<CompressionResult?> compressImage({
    required String imagePath,
    required int quality,
  }) async {
    LoggerUtil.d(TAG, 'Compressing image: ${LoggerUtil.truncatePath(imagePath)} with quality: $quality');
    
    try {
      final File originalFile = File(imagePath);
      final int originalSize = await originalFile.length();
      
      LoggerUtil.d(TAG, 'Original size: ${_formatFileSize(originalSize)}');
      
      final File? compressedFile = await ImageUtils.compressImage(
        file: originalFile,
        quality: quality,
      );
      
      if (compressedFile == null) {
        LoggerUtil.e(TAG, 'Compression failed - null result returned');
        return null;
      }
      
      final int compressedSize = await compressedFile.length();
      final double reduction = ImageUtils.calculateSizeReduction(originalSize, compressedSize);
      
      LoggerUtil.i(TAG, 'Compression complete - New size: ${_formatFileSize(compressedSize)}, Reduction: ${reduction.toStringAsFixed(2)}%');
      
      return CompressionResult(
        originalPath: imagePath,
        compressedPath: compressedFile.path,
        originalSize: originalSize,
        compressedSize: compressedSize,
        reduction: reduction,
      );
    } catch (e) {
      LoggerUtil.e(TAG, 'Error in compression service: $e');
      return null;
    }
  }
  
  @override
  Future<List<CompressionResult>> compressBatch({
    required List<String> imagePaths,
    required int quality,
  }) async {
    LoggerUtil.i(TAG, 'Starting batch compression of ${imagePaths.length} images with quality: $quality');
    
    List<CompressionResult> results = [];
    int successCount = 0;
    int errorCount = 0;
    
    for (int i = 0; i < imagePaths.length; i++) {
      final path = imagePaths[i];
      LoggerUtil.d(TAG, 'Processing image ${i+1}/${imagePaths.length}: ${LoggerUtil.truncatePath(path)}');
      
      final result = await compressImage(
        imagePath: path,
        quality: quality,
      );
      
      if (result != null) {
        results.add(result);
        successCount++;
        LoggerUtil.d(TAG, 'Successfully compressed image ${i+1}/${imagePaths.length}');
      } else {
        errorCount++;
        LoggerUtil.w(TAG, 'Failed to compress image ${i+1}/${imagePaths.length}');
      }
    }
    
    LoggerUtil.i(TAG, 'Batch compression complete - Success: $successCount, Errors: $errorCount');
    return results;
  }
  
  @override
  Future<File?> saveCompressedImage({
    required File compressedImage,
    String? customName,
  }) async {
    final imagePath = compressedImage.path;
    LoggerUtil.d(TAG, 'Saving compressed image: ${LoggerUtil.truncatePath(imagePath)}');
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = customName ?? path.basename(compressedImage.path);
      final savedPath = path.join(appDir.path, fileName);
      
      LoggerUtil.d(TAG, 'Destination path: ${LoggerUtil.truncatePath(savedPath)}');
      
      final savedFile = await compressedImage.copy(savedPath);
      LoggerUtil.i(TAG, 'Image saved successfully to ${LoggerUtil.truncatePath(savedPath)}');
      
      return savedFile;
    } catch (e) {
      LoggerUtil.e(TAG, 'Error saving compressed image: $e');
      return null;
    }
  }
  
  // Helper method for formatting file sizes in logs
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}