import 'package:equatable/equatable.dart';

class CompressionResult extends Equatable {
  final String originalPath;
  final String compressedPath;
  final int originalSize;
  final int compressedSize;
  final double reduction;

  const CompressionResult({
    required this.originalPath,
    required this.compressedPath,
    required this.originalSize,
    required this.compressedSize,
    required this.reduction,
  });

  @override
  List<Object?> get props => [
    originalPath,
    compressedPath,
    originalSize,
    compressedSize,
    reduction,
  ];
}