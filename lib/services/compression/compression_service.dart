import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:photoshrink/core/utils/image_utils.dart';
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
  @override
  Future<CompressionResult?> compressImage({
    required String imagePath,
    required int quality,
  }) async {
    try {
      final File originalFile = File(imagePath);
      final int originalSize = await originalFile.length();
      
      final File? compressedFile = await ImageUtils.compressImage(
        file: originalFile,
        quality: quality,
      );
      
      if (compressedFile == null) {
        return null;
      }
      
      final int compressedSize = await compressedFile.length();
      final double reduction = ImageUtils.calculateSizeReduction(originalSize, compressedSize);
      
      return CompressionResult(
        originalPath: imagePath,
        compressedPath: compressedFile.path,
        originalSize: originalSize,
        compressedSize: compressedSize,
        reduction: reduction,
      );
    } catch (e) {
      print('Error in compression service: $e');
      return null;
    }
  }
  
  @override
  Future<List<CompressionResult>> compressBatch({
    required List<String> imagePaths,
    required int quality,
  }) async {
    List<CompressionResult> results = [];
    
    for (String path in imagePaths) {
      final result = await compressImage(
        imagePath: path,
        quality: quality,
      );
      
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }
  
  @override
  Future<File?> saveCompressedImage({
    required File compressedImage,
    String? customName,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = customName ?? path.basename(compressedImage.path);
      final savedPath = path.join(appDir.path, fileName);
      
      return await compressedImage.copy(savedPath);
    } catch (e) {
      print('Error saving compressed image: $e');
      return null;
    }
  }
}