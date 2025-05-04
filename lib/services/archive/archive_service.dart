import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photoshrink/core/utils/logger_util.dart';

class ArchiveService {
  static const String TAG = 'ArchiveService';

  // Create a lossless archive from multiple images
  Future<File?> createImageArchive(List<String> imagePaths, {
    void Function(double progress, int processedImages, int totalImages)? onProgress,
  }) async {
    LoggerUtil.service(TAG, 'Creating archive from ${imagePaths.length} images');
    
    try {
      // Create archive
      final archive = Archive();
      int totalOriginalSize = 0;
      int processedCount = 0;
      
      // Add each image to the archive without quality loss
      for (int i = 0; i < imagePaths.length; i++) {
        final File imageFile = File(imagePaths[i]);
        final bytes = await imageFile.readAsBytes();
        totalOriginalSize += bytes.length;
        
        // Get original filename
        final fileName = path.basename(imagePaths[i]);
        LoggerUtil.d(TAG, 'Adding file to archive: ${LoggerUtil.truncatePath(fileName)}');
        
        // Add file to archive in original quality
        final archiveFile = ArchiveFile(
          fileName,
          bytes.length,
          bytes,
        );
        archive.addFile(archiveFile);
        
        // Report progress
        processedCount++;
        if (onProgress != null) {
          onProgress(processedCount / imagePaths.length, processedCount, imagePaths.length);
        }
      }
      
      // Create output directory
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(outputDir.path, 'photoshrink_$timestamp.phsrk');
      
      LoggerUtil.d(TAG, 'Encoding archive with compression level 9');
      // Encode and save the zip file with good compression level
      final zipData = ZipEncoder().encode(archive, level: 9); // Maximum compression level
      if (zipData == null) {
        LoggerUtil.e(TAG, 'Failed to encode zip data');
        return null;
      }
      
      final zipFile = File(outputPath);
      await zipFile.writeAsBytes(zipData);
      
      final archiveSize = await zipFile.length();
      final compressionRatio = (totalOriginalSize - archiveSize) / totalOriginalSize * 100;
      
      LoggerUtil.i(TAG, 'Archive created successfully at ${LoggerUtil.truncatePath(outputPath)}');
      LoggerUtil.i(TAG, 'Original size: ${_formatSize(totalOriginalSize)}, Archive size: ${_formatSize(archiveSize)}, Reduction: ${compressionRatio.toStringAsFixed(2)}%');
      
      return zipFile;
    } catch (e) {
      LoggerUtil.e(TAG, 'Error creating archive: $e');
      return null;
    }
  }
  
  // Extract images from an archive file
  Future<List<String>> extractArchive(String archivePath, {
    void Function(double progress, int processedImages, int totalImages)? onProgress,
    bool saveToGallery = false,
  }) async {
    LoggerUtil.service(TAG, 'Extracting archive: ${LoggerUtil.truncatePath(archivePath)}');
    
    try {
      final File archiveFile = File(archivePath);
      final bytes = await archiveFile.readAsBytes();
      
      // Decode the zip
      LoggerUtil.d(TAG, 'Decoding zip file');
      final archive = ZipDecoder().decodeBytes(bytes);
      final extractedPaths = <String>[];
      int processedCount = 0;
      int imageFiles = 0;
      
      // Count image files
      for (final file in archive) {
        if (file.isFile && _isImageFile(file.name)) {
          imageFiles++;
        }
      }
      
      LoggerUtil.i(TAG, 'Found $imageFiles image files in archive');
      
      // Get output directory
      final outputDir = await getTemporaryDirectory();
      
      // Extract each file
      for (final file in archive) {
        if (file.isFile && _isImageFile(file.name)) {
          final outputPath = path.join(outputDir.path, file.name);
          final outputFile = File(outputPath);
          await outputFile.writeAsBytes(file.content as List<int>);
          extractedPaths.add(outputPath);
          
          LoggerUtil.d(TAG, 'Extracted: ${LoggerUtil.truncatePath(file.name)}');
          
          // Save to gallery if requested
          if (saveToGallery) {
            final result = await ImageGallerySaver.saveFile(outputPath);
            LoggerUtil.d(TAG, 'Saved to gallery: ${result != null}');
          }
          
          // Report progress
          processedCount++;
          if (onProgress != null) {
            onProgress(processedCount / imageFiles, processedCount, imageFiles);
          }
        }
      }
      
      LoggerUtil.i(TAG, 'Extraction complete. Extracted ${extractedPaths.length} images');
      return extractedPaths;
    } catch (e) {
      LoggerUtil.e(TAG, 'Error extracting archive: $e');
      return [];
    }
  }
  
  // Check if file is an image based on extension
  bool _isImageFile(String filename) {
    final ext = path.extension(filename).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.bmp'].contains(ext);
  }
  
  // Revised share archive function that works with share_plus
  Future<bool> shareArchive(File archiveFile, {String? message}) async {
    LoggerUtil.service(TAG, 'Sharing archive: ${LoggerUtil.truncatePath(archiveFile.path)}');
    
    try {
      // First ensure the file exists
      if (!await archiveFile.exists()) {
        LoggerUtil.e(TAG, 'File does not exist: ${archiveFile.path}');
        return false;
      }
      
      // Create a temporary file with a .zip extension for better compatibility
      final tempDir = await getTemporaryDirectory();
      final shareFileName = 'photoshrink_archive_${DateTime.now().millisecondsSinceEpoch}.zip';
      final shareFilePath = '${tempDir.path}/$shareFileName';
      
      // Copy the original archive to the temporary file
      try {
        // Make sure to read and write in chunks to handle large files
        final input = archiveFile.openRead();
        final output = File(shareFilePath).openWrite();
        await input.pipe(output);
        await output.flush();
        await output.close();
        
        LoggerUtil.d(TAG, 'Created temporary sharing file: $shareFilePath');
      } catch (e) {
        LoggerUtil.e(TAG, 'Error creating temporary file for sharing: $e');
        return false;
      }
      
      // Set file permissions to ensure it's readable
      try {
        final tempFile = File(shareFilePath);
        if (Platform.isIOS || Platform.isMacOS) {
          await Process.run('chmod', ['644', tempFile.path]);
        }
      } catch (e) {
        // Ignore permission setting errors on some platforms
        LoggerUtil.w(TAG, 'Could not set file permissions: $e');
      }
      
      // Share the file using XFile for better compatibility
      final List<XFile> files = [XFile(shareFilePath)];
      final shareText = message ?? 'High-quality images shared from PhotoShrink';
      
      // Use try-catch to handle any share_plus errors
      try {
        await Share.shareXFiles(
          files,
          text: shareText,
        );
        
        LoggerUtil.i(TAG, 'Archive shared successfully');
        return true;
      } catch (e) {
        LoggerUtil.e(TAG, 'Error in Share.shareXFiles: $e');
        
        // Try an alternative approach with just the path
        try {
          await Share.share(
            shareFilePath,
            subject: shareText,
          );
          
          LoggerUtil.i(TAG, 'Archive shared using fallback method');
          return true;
        } catch (fallbackError) {
          LoggerUtil.e(TAG, 'Fallback sharing also failed: $fallbackError');
          return false;
        }
      }
    } catch (e) {
      LoggerUtil.e(TAG, 'Error sharing archive: $e');
      return false;
    }
  }
  
  // Calculate archive compression ratio
  Future<double> getCompressionRatio(String archivePath, List<String> originalPaths) async {
    try {
      final File archiveFile = File(archivePath);
      final int archiveSize = await archiveFile.length();
      
      int totalOriginalSize = 0;
      for (final path in originalPaths) {
        final File originalFile = File(path);
        totalOriginalSize += await originalFile.length();
      }
      
      // Calculate ratio (positive means reduction)
      final ratio = (totalOriginalSize - archiveSize) / totalOriginalSize * 100;
      LoggerUtil.d(TAG, 'Compression ratio: ${ratio.toStringAsFixed(2)}%');
      return ratio;
    } catch (e) {
      LoggerUtil.e(TAG, 'Error calculating compression ratio: $e');
      return 0.0;
    }
  }
  
  // Format file size for logging
  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}