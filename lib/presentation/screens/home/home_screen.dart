import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/constants/route_constants.dart';
import 'package:photoshrink/core/theme/app_theme.dart';
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/presentation/bloc/home/home_bloc.dart';
import 'package:photoshrink/presentation/bloc/home/home_event.dart';
import 'package:photoshrink/presentation/bloc/home/home_state.dart';
import 'package:photoshrink/presentation/common_widgets/ad_banner.dart';
import 'package:photoshrink/presentation/common_widgets/empty_state.dart';
import 'package:photoshrink/presentation/common_widgets/loading_indicator.dart';
import 'package:photoshrink/presentation/screens/home/widgets/compression_quality_selector.dart';
import 'package:photoshrink/presentation/screens/home/widgets/image_thumbnail_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeBloc _homeBloc = getIt<HomeBloc>();
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _homeBloc.add(LoadSettingsEvent());
    _loadAd();
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
      value: _homeBloc,
      child: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is NavigateToCompressionScreen) {
            Navigator.of(context).pushNamed(
              RouteConstants.compression,
              arguments: {
                'imagePaths': state.imagePaths,
                'quality': state.quality,
              },
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppConstants.appName),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).pushNamed(RouteConstants.settings);
                  },
                ),
              ],
            ),
            body: _buildBody(context, state),
            floatingActionButton: _buildFloatingActionButton(context, state),
            bottomNavigationBar: _buildAdBanner(),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state is HomeInitial || state is HomeLoading) {
      return const LoadingIndicator();
    } else if (state is HomeLoadSuccess) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CompressionQualitySelector(
              quality: state.compressionQuality,
              onChanged: (value) {
                context.read<HomeBloc>().add(
                      CompressionQualityChangedEvent(value),
                    );
              },
            ),
          ),
          Expanded(
            child: state.selectedImagePaths.isEmpty
                ? EmptyState(
                    icon: Icons.image,
                    title: 'No Images Selected',
                    message: 'Tap the button below to select images for compression.',
                    buttonLabel: 'Select Images',
                    onButtonPressed: () {
                      context.read<HomeBloc>().add(
                            const ImageSelectionRequestedEvent(),
                          );
                    },
                  )
                : ImageThumbnailGrid(
                    imagePaths: state.selectedImagePaths,
                    onRemove: (index) {
                      // Implement removal of an image from the grid
                      final updatedImagePaths = List<String>.from(state.selectedImagePaths);
                      updatedImagePaths.removeAt(index);
                      context.read<HomeBloc>().add(
                            ImagesSelectedEvent(updatedImagePaths),
                          );
                    },
                  ),
          ),
        ],
      );
    } else {
      return const Center(
        child: Text('Something went wrong. Please try again.'),
      );
    }
  }

  Widget _buildFloatingActionButton(BuildContext context, HomeState state) {
    if (state is HomeLoadSuccess) {
      return state.selectedImagePaths.isEmpty
          ? FloatingActionButton(
              onPressed: () {
                context.read<HomeBloc>().add(
                      const ImageSelectionRequestedEvent(),
                    );
              },
              child: const Icon(Icons.add_photo_alternate),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'add_more',
                  onPressed: () {
                    context.read<HomeBloc>().add(
                          const ImageSelectionRequestedEvent(),
                        );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'compress',
                  onPressed: () {
                    context.read<HomeBloc>().add(StartCompressionEvent());
                  },
                  icon: const Icon(Icons.compress),
                  label: const Text('Compress'),
                ),
              ],
            );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAdBanner() {
    if (AppConstants.enableAds && _isAdLoaded && _bannerAd != null) {
      return AdBanner(ad: _bannerAd!);
    } else {
      return const SizedBox.shrink();
    }
  }
}
