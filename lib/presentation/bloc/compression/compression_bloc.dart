import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/data/models/compression_history.dart';
import 'package:photoshrink/data/models/compression_result.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_event.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_state.dart';
import 'package:photoshrink/services/analytics/analytics_service.dart';
import 'package:photoshrink/services/archive/archive_service.dart';
import 'package:photoshrink/services/compression/compression_service.dart';
import 'package:photoshrink/services/storage/storage_service.dart';

class CompressionBloc extends Bloc<CompressionEvent, CompressionState> {
  final ArchiveService _archiveService = ArchiveService();
  final StorageService _storageService;
  final AnalyticsService _analyticsService;
  bool _isCompressing = false;

  CompressionBloc({
    required StorageService storageService,
    required AnalyticsService analyticsService, required CompressionService compressionService,
  })  : _storageService = storageService,
        _analyticsService = analyticsService,
        super(CompressionInitial()) {
    on<StartCompressionProcess>(_onStartCompressionProcess);
    on<CancelCompression>(_onCancelCompression);
    on<ExtractArchiveEvent>(_onExtractArchive);
  }

  Future<void> _onStartCompressionProcess(
    StartCompressionProcess event,
    Emitter<CompressionState> emit,
  ) async {
    if (_isCompressing) return;
    _isCompressing = true;

    final List<String> imagePaths = event.imagePaths;
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
      final File? archiveFile = await _archiveService.createImageArchive(
        imagePaths, 
        onProgress: (progress, processedImages, totalImages) {
          if (!_isCompressing) return; // Stop if compression was cancelled
          
          emit(CompressionInProgress(
            totalImages: totalImages,
            processedImages: processedImages,
            progress: progress,
            results: const [],
          ));
        },
      );
      
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
          ? ((originalTotalSize - archiveSize) / originalTotalSize) * 100
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
        quality: 100, // We're using lossless, so quality is 100%
        sizeReduction: totalReduction,
      );

      emit(CompressionSuccess(
        results: [archiveResult],
        totalReduction: totalReduction,
        originalTotalSize: originalTotalSize,
        compressedTotalSize: archiveSize,
      ));
    } catch (e) {
      emit(CompressionError('Failed to create archive: ${e.toString()}'));
    } finally {
      _isCompressing = false;
    }
  }

  void _onCancelCompression(
    CancelCompression event,
    Emitter<CompressionState> emit,
  ) {
    emit(CompressionCancelled());
    _isCompressing = false;
  }
  
  Future<void> _onExtractArchive(
    ExtractArchiveEvent event,
    Emitter<CompressionState> emit,
  ) async {
    emit(ExtractionInProgress(
      totalImages: 0, // We don't know yet how many images are in the archive
      processedImages: 0,
      progress: 0.0,
    ));
    
    try {
      final extractedPaths = await _archiveService.extractArchive(
        event.archivePath,
        saveToGallery: event.saveToGallery,
        onProgress: (progress, processedImages, totalImages) {
          emit(ExtractionInProgress(
            totalImages: totalImages,
            processedImages: processedImages,
            progress: progress,
          ));
        },
      );
      
      if (extractedPaths.isEmpty) {
        emit(const ExtractionError('No images found in the archive'));
      } else {
        emit(ExtractionSuccess(
          extractedPaths: extractedPaths,
          count: extractedPaths.length,
        ));
      }
    } catch (e) {
      emit(ExtractionError('Failed to extract archive: ${e.toString()}'));
    }
  }
}