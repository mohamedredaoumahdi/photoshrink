import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photoshrink/core/utils/image_utils.dart';
import 'package:photoshrink/data/models/compression_result.dart';

class CompressionResultCard extends StatelessWidget {
  final CompressionResult result;
  final VoidCallback onTap;

  const CompressionResultCard({
    Key? key,
    required this.result,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(result.compressedPath),
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFileName(result.originalPath),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Reduce font size
                        overflow: TextOverflow.ellipsis, // Add overflow property
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Wrap( // Use Wrap instead of Row
                      spacing: 8, // horizontal spacing
                      runSpacing: 4, // vertical spacing
                      children: [
                        _buildInfoChip(
                          'Original',
                          ImageUtils.formatFileSize(result.originalSize),
                        ),
                        _buildInfoChip(
                          'Compressed',
                          ImageUtils.formatFileSize(result.compressedSize),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saved ${result.reduction.toStringAsFixed(1)}% in file size',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 12, // Reduce font size
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduce padding
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10, // Reduce font size
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 3), // Reduce spacing
          Text(
            value,
            style: const TextStyle(
              fontSize: 10, // Reduce font size
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getFileName(String path) {
    final filename = path.split('/').last;
    // Truncate filename if it's too long
    return filename.length > 20 
        ? '${filename.substring(0, 18)}...' 
        : filename;
  }
}