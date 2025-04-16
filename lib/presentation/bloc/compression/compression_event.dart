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
    required this.quality,
  });

  @override
  List<Object?> get props => [imagePaths, quality];
}

class CancelCompression extends CompressionEvent {}