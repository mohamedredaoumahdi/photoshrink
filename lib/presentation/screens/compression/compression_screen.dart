import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/constants/route_constants.dart';
import 'package:photoshrink/core/utils/image_utils.dart';
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_bloc.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_event.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_state.dart';
import 'package:photoshrink/presentation/common_widgets/ad_banner.dart';
import 'package:photoshrink/presentation/screens/compression/widgets/compression_progress.dart';
import 'package:photoshrink/presentation/screens/compression/widgets/compression_result_card.dart';

class CompressionScreen extends StatefulWidget {
  final List<String> imagePaths;
  final int quality;

  const CompressionScreen({
    Key? key,
    required this.imagePaths,
    required this.quality,
  }) : super(key: key);

  @override
  State<CompressionScreen> createState() => _CompressionScreenState();
}

class _CompressionScreenState extends State<CompressionScreen> {
  final CompressionBloc _compressionBloc = getIt<CompressionBloc>();
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
    
    // Start compression process
    _compressionBloc.add(StartCompressionProcess(
      imagePaths: widget.imagePaths,
      quality: widget.quality,
    ));
  }

  void _loadAd() {
    if (AppConstants.enableAds) {
      _bannerAd = BannerAd(
        adUnitId: AppConstants.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
          },
        ),
      );

      _bannerAd?.load();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _compressionBloc,
      child: BlocConsumer<CompressionBloc, CompressionState>(
        listener: (context, state) {
          if (state is CompressionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop();
          } else if (state is NavigateToPreviewScreen) {
            Navigator.of(context).pushNamed(
              RouteConstants.preview,
              arguments: {
                'originalPath': state.result.originalPath,
                'compressedPath': state.result.compressedPath,
                'originalSize': state.result.originalSize,
                'compressedSize': state.result.compressedSize,
              },
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Compressing Images'),
              leading: state is CompressionInProgress
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _compressionBloc.add(CancelCompression());
                        Navigator.of(context).pop();
                      },
                    )
                  : const BackButton(),
            ),
            body: _buildBody(context, state),
            bottomNavigationBar: _buildAdBanner(),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CompressionState state) {
    if (state is CompressionInProgress) {
      return CompressionProgress(
        progress: state.progress,
        processedImages: state.processedImages,
        totalImages: state.totalImages,
      );
    } else if (state is CompressionSuccess) {
      return _buildCompressionResults(context, state);
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Widget _buildCompressionResults(BuildContext context, CompressionSuccess state) {
    return Column(
      children: [
        // Summary card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Compression Complete!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.results.length} images compressed',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        'Original Size',
                        ImageUtils.formatFileSize(state.originalTotalSize),
                      ),
                      _buildStatColumn(
                        'Compressed Size',
                        ImageUtils.formatFileSize(state.compressedTotalSize),
                      ),
                      _buildStatColumn(
                        'Reduction',
                        '${state.totalReduction.toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final result = state.results[index];
              return CompressionResultCard(
                result: result,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    RouteConstants.preview,
                    arguments: {
                      'originalPath': result.originalPath,
                      'compressedPath': result.compressedPath,
                      'originalSize': result.originalSize,
                      'compressedSize': result.compressedSize,
                    },
                  );
                },
              );
            },
          ),
        ),
        
        // Done button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAdBanner() {
    if (AppConstants.enableAds && _isAdLoaded && _bannerAd != null) {
      return AdBanner(ad: _bannerAd!);
    } else {
      return const SizedBox.shrink();
    }
  }
}