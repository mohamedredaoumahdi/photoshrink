import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/utils/image_utils.dart';
import 'package:photoshrink/data/models/compression_history.dart';
import 'package:photoshrink/data/models/compression_result.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_event.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_state.dart';
import 'package:photoshrink/services/analytics/analytics_service.dart';
import 'package:photoshrink/services/compression/compression_service.dart';
import 'package:photoshrink/services/storage/storage_service.dart';

class CompressionBloc extends Bloc<CompressionEvent, CompressionState> {
  final CompressionService _compressionService;
  final StorageService _storageService;
  final AnalyticsService _analyticsService;
  bool _isCompressing = false;

  CompressionBloc({
    required CompressionService compressionService,
    required StorageService storageService,
    required AnalyticsService analyticsService,
  })  : _compressionService = compressionService,
        _storageService = storageService,
        _analyticsService = analyticsService,
        super(CompressionInitial()) {
    on<StartCompressionProcess>(_onStartCompressionProcess);
    on<CancelCompression>(_onCancelCompression);
  }

  Future<void> _onStartCompressionProcess(
    StartCompressionProcess event,
    Emitter<CompressionState> emit,
  ) async {
    if (_isCompressing) return;
    _isCompressing = true;

    final List<String> imagePaths = event.imagePaths;
    final int quality = event.quality;
    final int totalImages = imagePaths.length;

    if (totalImages == 0) {
      emit(const CompressionError(AppConstants.noImagesSelectedMessage));
      _isCompressing = false;
      return;
    }

    emit(CompressionInProgress(
      totalImages: totalImages,
      processedImages: 0,
      progress: 0.0,
      results: const [],
    ));

    try {
      // Create an archive file from the images
      final File? archiveFile = await _createImageArchive(imagePaths, emit);
      
      if (archiveFile == null) {
        emit(const CompressionError('Failed to create archive file'));
        _isCompressing = false;
        return;
      }
      
      // Calculate sizes
      int originalTotalSize = 0;
      for (final imagePath in imagePaths) {
        final File originalFile = File(imagePath);
        originalTotalSize += await originalFile.length();
      }
      
      final int archiveSize = await archiveFile.length();
      final double totalReduction = originalTotalSize > 0
          ? ImageUtils.calculateSizeReduction(originalTotalSize, archiveSize)
          : 0.0;
          
      // Create a single result for the archive
      final CompressionResult archiveResult = CompressionResult(
        originalPath: "Multiple Images (${imagePaths.length})",
        compressedPath: archiveFile.path,
        originalSize: originalTotalSize,
        compressedSize: archiveSize,
        reduction: totalReduction,
      );
      
      // Save to compression history
      await _storageService.addCompressionHistory(
        CompressionHistory.fromCompressionResult(archiveResult),
      );
      
      // Log analytics
      await _analyticsService.logCompression(
        imageCount: imagePaths.length,
        quality: quality,
        sizeReduction: totalReduction,
      );

      emit(CompressionSuccess(
        results: [archiveResult],
        totalReduction: totalReduction,
        originalTotalSize: originalTotalSize,
        compressedTotalSize: archiveSize,
      ));
    } catch (e) {
      emit(CompressionError('Failed to compress images: ${e.toString()}'));
    } finally {
      _isCompressing = false;
    }
  }
  
  Future<File?> _createImageArchive(
    List<String> imagePaths, 
    Emitter<CompressionState> emit
  ) async {
    try {
      // Create archive
      final archive = Archive();
      int totalProcessed = 0;
      
      // Process each image
      for (final imagePath in imagePaths) {
        if (state is CompressionCancelled) {
          return null;
        }
        
        try {
          final File imageFile = File(imagePath);
          final bytes = await imageFile.readAsBytes();
          
          // Get original filename
          final fileName = path.basename(imagePath);
          
          // Add file to archive
          final archiveFile = ArchiveFile(
            fileName,
            bytes.length,
            bytes,
          );
          archive.addFile(archiveFile);
          
          // Update progress
          totalProcessed++;
          final double progress = totalProcessed / imagePaths.length;
          emit(CompressionInProgress(
            totalImages: imagePaths.length,
            processedImages: totalProcessed,
            progress: progress,
            results: const [],
          ));
        } catch (e) {
          print('Error adding file to archive: $e');
          // Continue with next file
        }
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

  void _onCancelCompression(
    CancelCompression event,
    Emitter<CompressionState> emit,
  ) {
    emit(CompressionCancelled());
    _isCompressing = false;
  }
  
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
        }
      }
      
      return extractedPaths;
    } catch (e) {
      print('Error extracting archive: $e');
      return [];
    }
  }
}