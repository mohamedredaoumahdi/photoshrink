import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:photoshrink/data/models/compression_history.dart';
import 'package:photoshrink/data/models/compression_result.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_event.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_state.dart';
import 'package:photoshrink/services/analytics/analytics_service.dart';
import 'package:photoshrink/services/archive/archive_service.dart';
import 'package:photoshrink/services/compression/compression_service.dart';
import 'package:photoshrink/services/storage/storage_service.dart';

class CompressionBloc extends Bloc<CompressionEvent, CompressionState> {
  static const String TAG = 'CompressionBloc';
  
  final ArchiveService _archiveService = ArchiveService();
  final StorageService _storageService;
  final AnalyticsService _analyticsService;
  final CompressionService _compressionService;
  bool _isCompressing = false;

  CompressionBloc({
    required StorageService storageService,
    required AnalyticsService analyticsService,
    required CompressionService compressionService,
  })  : _storageService = storageService,
        _analyticsService = analyticsService,
        _compressionService = compressionService,
        super(CompressionInitial()) {
    on<StartCompressionProcess>(_onStartCompressionProcess);
    on<CancelCompression>(_onCancelCompression);
    on<ExtractArchiveEvent>(_onExtractArchive);
    
    LoggerUtil.i(TAG, 'CompressionBloc initialized');
  }

  Future<void> _onStartCompressionProcess(
    StartCompressionProcess event,
    Emitter<CompressionState> emit,
  ) async {
    if (_isCompressing) {
      LoggerUtil.w(TAG, 'Compression already in progress, ignoring request');
      return;
    }
    
    _isCompressing = true;
    LoggerUtil.i(TAG, 'Starting compression process for ${event.imagePaths.length} images');

    final List<String> imagePaths = event.imagePaths;
    final int totalImages = imagePaths.length;

    if (totalImages == 0) {
      LoggerUtil.e(TAG, 'No images selected for compression');
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
      LoggerUtil.d(TAG, 'Creating archive file');
      // Create an archive file from the images
      final File? archiveFile = await _archiveService.createImageArchive(
        imagePaths, 
        onProgress: (progress, processedImages, totalImages) {
          if (!_isCompressing) {
            LoggerUtil.d(TAG, 'Compression was cancelled, stopping progress updates');
            return; // Stop if compression was cancelled
          }
          
          LoggerUtil.v(TAG, 'Progress update: ${(progress * 100).toStringAsFixed(1)}% ($processedImages/$totalImages)');
          emit(CompressionInProgress(
            totalImages: totalImages,
            processedImages: processedImages,
            progress: progress,
            results: const [],
          ));
        },
      );
      
      if (archiveFile == null) {
        LoggerUtil.e(TAG, 'Failed to create archive file');
        emit(const CompressionError('Failed to create archive file'));
        _isCompressing = false;
        return;
      }
      
      LoggerUtil.d(TAG, 'Calculating file sizes');
      // Calculate sizes
      int originalTotalSize = 0;
      for (final imagePath in imagePaths) {
        final File originalFile = File(imagePath);
        final fileSize = await originalFile.length();
        originalTotalSize += fileSize;
        LoggerUtil.v(TAG, 'Original file size for ${LoggerUtil.truncatePath(imagePath)}: $fileSize bytes');
      }
      
      final int archiveSize = await archiveFile.length();
      final double totalReduction = originalTotalSize > 0
          ? ((originalTotalSize - archiveSize) / originalTotalSize) * 100
          : 0.0;
          
      LoggerUtil.i(TAG, 'Archive created: ${LoggerUtil.truncatePath(archiveFile.path)}');
      LoggerUtil.i(TAG, 'Total original size: $originalTotalSize bytes, Archive size: $archiveSize bytes');
      LoggerUtil.i(TAG, 'Size reduction: ${totalReduction.toStringAsFixed(2)}%');
      
      // Create a single result for the archive
      final CompressionResult archiveResult = CompressionResult(
        originalPath: "Multiple Images (${imagePaths.length})",
        compressedPath: archiveFile.path,
        originalSize: originalTotalSize,
        compressedSize: archiveSize,
        reduction: totalReduction,
      );
      
      LoggerUtil.d(TAG, 'Saving to compression history');
      // Save to compression history
      await _storageService.addCompressionHistory(
        CompressionHistory.fromCompressionResult(archiveResult),
      );
      
      LoggerUtil.d(TAG, 'Logging analytics');
      // Log analytics
      await _analyticsService.logCompression(
        imageCount: imagePaths.length,
        quality: 100, // We're using lossless, so quality is 100%
        sizeReduction: totalReduction,
      );

      LoggerUtil.i(TAG, 'Compression process completed successfully');
      emit(CompressionSuccess(
        results: [archiveResult],
        totalReduction: totalReduction,
        originalTotalSize: originalTotalSize,
        compressedTotalSize: archiveSize,
      ));
    } catch (e) {
      LoggerUtil.e(TAG, 'Error during compression: $e');
      emit(CompressionError('Failed to create archive: ${e.toString()}'));
    } finally {
      _isCompressing = false;
    }
  }

  void _onCancelCompression(
    CancelCompression event,
    Emitter<CompressionState> emit,
  ) {
    LoggerUtil.w(TAG, 'Compression cancelled by user');
    emit(CompressionCancelled());
    _isCompressing = false;
  }
  
  Future<void> _onExtractArchive(
    ExtractArchiveEvent event,
    Emitter<CompressionState> emit,
  ) async {
    LoggerUtil.i(TAG, 'Starting archive extraction: ${LoggerUtil.truncatePath(event.archivePath)}');
    LoggerUtil.d(TAG, 'Save to gallery: ${event.saveToGallery}');
    
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
          LoggerUtil.v(TAG, 'Extraction progress: ${(progress * 100).toStringAsFixed(1)}% ($processedImages/$totalImages)');
          emit(ExtractionInProgress(
            totalImages: totalImages,
            processedImages: processedImages,
            progress: progress,
          ));
        },
      );
      
      if (extractedPaths.isEmpty) {
        LoggerUtil.e(TAG, 'No images found in the archive');
        emit(const ExtractionError('No images found in the archive'));
      } else {
        LoggerUtil.i(TAG, 'Extraction completed successfully: ${extractedPaths.length} images extracted');
        emit(ExtractionSuccess(
          extractedPaths: extractedPaths,
          count: extractedPaths.length,
        ));
      }
    } catch (e) {
      LoggerUtil.e(TAG, 'Error during extraction: $e');
      emit(ExtractionError('Failed to extract archive: ${e.toString()}'));
    }
  }
}