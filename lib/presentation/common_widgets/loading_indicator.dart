import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:photoshrink/core/theme/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/loading_animation.json',
            width: 150,
            height: 150,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}