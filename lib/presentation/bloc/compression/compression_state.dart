import 'package:equatable/equatable.dart';
import 'package:photoshrink/data/models/compression_result.dart';

abstract class CompressionState extends Equatable {
  const CompressionState();

  @override
  List<Object?> get props => [];
}

class CompressionInitial extends CompressionState {}

class CompressionInProgress extends CompressionState {
  final int totalImages;
  final int processedImages;
  final double progress;
  final List<CompressionResult> results;

  const CompressionInProgress({
    required this.totalImages,
    required this.processedImages,
    required this.progress,
    this.results = const [],
  });

  @override
  List<Object?> get props => [totalImages, processedImages, progress, results];
}

class CompressionSuccess extends CompressionState {
  final List<CompressionResult> results;
  final double totalReduction;
  final int originalTotalSize;
  final int compressedTotalSize;

  const CompressionSuccess({
    required this.results,
    required this.totalReduction,
    required this.originalTotalSize,
    required this.compressedTotalSize,
  });

  @override
  List<Object?> get props => [
        results,
        totalReduction,
        originalTotalSize,
        compressedTotalSize,
      ];
}

class CompressionCancelled extends CompressionState {}

class CompressionError extends CompressionState {
  final String message;

  const CompressionError(this.message);

  @override
  List<Object?> get props => [message];
}

// Extraction states
class ExtractionInProgress extends CompressionState {
  final int totalImages;
  final int processedImages;
  final double progress;

  const ExtractionInProgress({
    required this.totalImages,
    required this.processedImages,
    required this.progress,
  });

  @override
  List<Object?> get props => [totalImages, processedImages, progress];
}

class ExtractionSuccess extends CompressionState {
  final List<String> extractedPaths;
  final int count;

  const ExtractionSuccess({
    required this.extractedPaths,
    required this.count,
  });

  @override
  List<Object?> get props => [extractedPaths, count];
}

class ExtractionError extends CompressionState {
  final String message;

  const ExtractionError(this.message);

  @override
  List<Object?> get props => [message];
}

class NavigateToPreviewScreen extends CompressionState {
  final CompressionResult result;

  const NavigateToPreviewScreen(this.result);

  @override
  List<Object?> get props => [result];
}