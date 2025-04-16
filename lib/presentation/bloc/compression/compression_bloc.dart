import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    final List<CompressionResult> results = [];
    int processedImages = 0;

    try {
      for (final imagePath in imagePaths) {
        if (state is CompressionCancelled) {
          _isCompressing = false;
          return;
        }

        final CompressionResult? result = await _compressionService.compressImage(
          imagePath: imagePath,
          quality: quality,
        );

        if (result != null) {
          results.add(result);
          processedImages++;

          // Save to compression history
          await _storageService.addCompressionHistory(
            CompressionHistory.fromCompressionResult(result),
          );

          // Update progress
          final double progress = processedImages / totalImages;
          emit(CompressionInProgress(
            totalImages: totalImages,
            processedImages: processedImages,
            progress: progress,
            results: List.from(results),
          ));
        }
      }

      // Calculate total reduction
      int originalTotalSize = 0;
      int compressedTotalSize = 0;
      for (final result in results) {
        originalTotalSize += result.originalSize;
        compressedTotalSize += result.compressedSize;
      }

      final double totalReduction = originalTotalSize > 0
          ? ImageUtils.calculateSizeReduction(originalTotalSize, compressedTotalSize)
          : 0.0;

      // Log analytics
      await _analyticsService.logCompression(
        imageCount: results.length,
        quality: quality,
        sizeReduction: totalReduction,
      );

      emit(CompressionSuccess(
        results: results,
        totalReduction: totalReduction,
        originalTotalSize: originalTotalSize,
        compressedTotalSize: compressedTotalSize,
      ));
    } catch (e) {
      emit(CompressionError('Failed to compress images: ${e.toString()}'));
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
}