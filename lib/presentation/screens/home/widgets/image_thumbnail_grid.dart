import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photoshrink/core/theme/app_theme.dart';

class ImageThumbnailGrid extends StatelessWidget {
  final List<String> imagePaths;
  final Function(int) onRemove;

  const ImageThumbnailGrid({
    Key? key,
    required this.imagePaths,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                'Selected Images (${imagePaths.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Clear all selected images
                  for (int i = imagePaths.length - 1; i >= 0; i--) {
                    onRemove(i);
                  }
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              return _buildImageThumbnail(context, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(BuildContext context, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.file(
              File(imagePaths[index]),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => onRemove(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel,
                color: AppTheme.errorColor,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}