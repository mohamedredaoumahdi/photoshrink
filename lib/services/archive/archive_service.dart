import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';


class ArchiveService {
  // Create a compressed archive from multiple images
  Future<File?> createImageArchive(List<String> imagePaths) async {
    try {
      // Create archive
      final archive = Archive();
      int totalOriginalSize = 0;
      
      // Add each image to the archive
      for (int i = 0; i < imagePaths.length; i++) {
        final File imageFile = File(imagePaths[i]);
        final bytes = await imageFile.readAsBytes();
        totalOriginalSize += bytes.length;
        
        // Get original filename
        final fileName = path.basename(imagePaths[i]);
        
        // Add file to archive
        final archiveFile = ArchiveFile(
          fileName,
          bytes.length,
          bytes,
        );
        archive.addFile(archiveFile);
      }
      
      // Create output directory
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(outputDir.path, 'photoshrink_$timestamp.zip');
      
      // Encode and save the zip file
      final zipData = ZipEncoder().encode(archive);
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
  Future<List<String>> extractArchive(String archivePath) async {
    try {
      final File archiveFile = File(archivePath);
      final bytes = await archiveFile.readAsBytes();
      
      // Decode the zip
      final archive = ZipDecoder().decodeBytes(bytes);
      final extractedPaths = <String>[];
      
      // Get output directory
      final outputDir = await getTemporaryDirectory();
      
      // Extract each file
      for (final file in archive) {
        if (file.isFile) {
          final outputPath = path.join(outputDir.path, file.name);
          final outputFile = File(outputPath);
          await outputFile.writeAsBytes(file.content as List<int>);
          extractedPaths.add(outputPath);
          
          // Save to gallery
          await ImageGallerySaver.saveFile(outputPath);
        }
      }
      
      return extractedPaths;
    } catch (e) {
      print('Error extracting archive: $e');
      return [];
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