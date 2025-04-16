import 'package:equatable/equatable.dart';
import 'package:photoshrink/data/models/compression_result.dart';

class CompressionHistory extends Equatable {
  final String originalPath;
  final String compressedPath;
  final int originalSize;
  final int compressedSize;
  final double reduction;
  final DateTime timestamp;

  const CompressionHistory({
    required this.originalPath,
    required this.compressedPath,
    required this.originalSize,
    required this.compressedSize,
    required this.reduction,
    required this.timestamp,
  });

  factory CompressionHistory.fromCompressionResult(
    CompressionResult result,
  ) {
    return CompressionHistory(
      originalPath: result.originalPath,
      compressedPath: result.compressedPath,
      originalSize: result.originalSize,
      compressedSize: result.compressedSize,
      reduction: result.reduction,
      timestamp: DateTime.now(),
    );
  }

  factory CompressionHistory.fromJson(Map<String, dynamic> json) {
    return CompressionHistory(
      originalPath: json['originalPath'] as String,
      compressedPath: json['compressedPath'] as String,
      originalSize: json['originalSize'] as int,
      compressedSize: json['compressedSize'] as int,
      reduction: json['reduction'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalPath': originalPath,
      'compressedPath': compressedPath,
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'reduction': reduction,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    originalPath,
    compressedPath,
    originalSize,
    compressedSize,
    reduction,
    timestamp,
  ];
}