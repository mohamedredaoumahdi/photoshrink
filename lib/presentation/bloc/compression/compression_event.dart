import 'package:equatable/equatable.dart';

abstract class CompressionEvent extends Equatable {
  const CompressionEvent();

  @override
  List<Object?> get props => [];
}

class StartCompressionProcess extends CompressionEvent {
  final List<String> imagePaths;
  final int quality;

  const StartCompressionProcess({
    required this.imagePaths,
    this.quality = 100, // We use 100 for lossless archiving
  });

  @override
  List<Object?> get props => [imagePaths, quality];
}

class CancelCompression extends CompressionEvent {}

class ExtractArchiveEvent extends CompressionEvent {
  final String archivePath;
  final bool saveToGallery;
  
  const ExtractArchiveEvent({
    required this.archivePath,
    this.saveToGallery = true,
  });
  
  @override
  List<Object?> get props => [archivePath, saveToGallery];
}