import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:photoshrink/core/theme/app_theme.dart';

class CompressionProgress extends StatelessWidget {
  final double progress;
  final int processedImages;
  final int totalImages;

  const CompressionProgress({
    Key? key,
    required this.progress,
    required this.processedImages,
    required this.totalImages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/compressing_animation.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 24),
            Text(
              'Compressing Images...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '$processedImages of $totalImages completed',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Please do not close the app during compression.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}