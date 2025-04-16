import 'package:flutter/material.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/theme/app_theme.dart';

class CompressionQualitySelector extends StatelessWidget {
  final int quality;
  final ValueChanged<int> onChanged;

  const CompressionQualitySelector({
    Key? key,
    required this.quality,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compression Quality',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Low'),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primaryColor,
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  min: 10,
                  max: 100,
                  divisions: 9,
                  value: quality.toDouble(),
                  onChanged: (value) {
                    onChanged(value.toInt());
                  },
                ),
              ),
            ),
            const Text('High'),
          ],
        ),
        Center(
          child: Text(
            _getQualityLabel(quality),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _getQualityLabel(int quality) {
    if (quality <= 30) {
      return 'Low (Maximum Compression)';
    } else if (quality <= 60) {
      return 'Medium (Balanced)';
    } else {
      return 'High (Better Quality)';
    }
  }
}