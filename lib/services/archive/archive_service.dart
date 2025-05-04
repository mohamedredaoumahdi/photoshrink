import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';

class ArchiveService {
  // Create a lossless archive from multiple images
  Future<File?> createImageArchive(List<String> imagePaths, {
    void Function(double progress, int processedImages, int totalImages)? onProgress,
  }) async {
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
      
      // Encode and save the zip file with good compression level
      final zipData = ZipEncoder().encode(archive, level: 9); // Maximum compression level
      if (zipData == null) return null;
      
      final zipFile = File(outputPath);
      await zipFile.writeAsBytes(zipData);
      
      return zipFile;
    } catch (e) {
      print('Error creating archive: $e');
      return null;
    }
  }
  
  // Extract images from an archive file
  Future<List<String>> extractArchive(String archivePath, {
    void Function(double progress, int processedImages, int totalImages)? onProgress,
    bool saveToGallery = false,
  }) async {
    try {
      final File archiveFile = File(archivePath);
      final bytes = await archiveFile.readAsBytes();
      
      // Decode the zip
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
      
      // Get output directory
      final outputDir = await getTemporaryDirectory();
      
      // Extract each file
      for (final file in archive) {
        if (file.isFile && _isImageFile(file.name)) {
          final outputPath = path.join(outputDir.path, file.name);
          final outputFile = File(outputPath);
          await outputFile.writeAsBytes(file.content as List<int>);
          extractedPaths.add(outputPath);
          
          // Save to gallery if requested
          if (saveToGallery) {
            await ImageGallerySaver.saveFile(outputPath);
          }
          
          // Report progress
          processedCount++;
          if (onProgress != null) {
            onProgress(processedCount / imageFiles, processedCount, imageFiles);
          }
        }
      }
      
      return extractedPaths;
    } catch (e) {
      print('Error extracting archive: $e');
      return [];
    }
  }
  
  // Check if file is an image based on extension
  bool _isImageFile(String filename) {
    final ext = path.extension(filename).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.bmp'].contains(ext);
  }
  
  // Share archive file
  Future<bool> shareArchive(File archiveFile, {String? message}) async {
    try {
      await Share.shareXFiles(
        [XFile(archiveFile.path)],
        text: message ?? 'High-quality images shared from PhotoShrink',
      );
      return true;
    } catch (e) {
      print('Error sharing archive: $e');
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
      return (totalOriginalSize - archiveSize) / totalOriginalSize * 100;
    } catch (e) {
      return 0.0;
    }
  }
}