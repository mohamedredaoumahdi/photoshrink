import 'dart:io';
import 'package:before_after/before_after.dart';
import 'package:flutter/material.dart';
//import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/theme/app_theme.dart';
import 'package:photoshrink/core/utils/image_utils.dart';
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/services/analytics/analytics_service.dart';

class PreviewScreen extends StatefulWidget {
  final String originalPath;
  final String compressedPath;
  final int originalSize;
  final int compressedSize;

  const PreviewScreen({
    Key? key,
    required this.originalPath,
    required this.compressedPath,
    required this.originalSize,
    required this.compressedSize,
  }) : super(key: key);

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();
  //BannerAd? _bannerAd;
  final bool _isAdLoaded = false;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAd();
    
    // Log event
    _analyticsService.logSelectContent(
      contentType: 'image_preview',
      itemId: widget.compressedPath,
    );
  }

  void _loadAd() {
    // if (AppConstants.enableAds) {
    //   _bannerAd = BannerAd(
    //     adUnitId: AppConstants.bannerAdUnitId,
    //     size: AdSize.banner,
    //     request: const AdRequest(),
    //     listener: BannerAdListener(
    //       onAdLoaded: (ad) {
    //         setState(() {
    //           _isAdLoaded = true;
    //         });
    //       },
    //       onAdFailedToLoad: (ad, error) {
    //         ad.dispose();
    //       },
    //     ),
    //   );

    //   _bannerAd?.load();
    // }
  }

  @override
  void dispose() {
    _tabController.dispose();
    //_bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _saveToGallery() async {
    try {
      final compressedFile = File(widget.compressedPath);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = widget.compressedPath.split('/').last;
      final savedPath = '${directory.path}/$fileName';
      
      await compressedFile.copy(savedPath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.savingSuccessMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.savingFailureMessage)),
      );
    }
  }

  Future<void> _shareImage() async {
  try {
    final XFile file = XFile(widget.compressedPath);
    await Share.shareXFiles(
      [file],
      text: 'Check out this compressed image from PhotoShrink!',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppConstants.shareSuccessMessage)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to share the image. Please try again.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final double reduction = ImageUtils.calculateSizeReduction(
      widget.originalSize,
      widget.compressedSize,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Preview'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Compare'),
            Tab(text: 'Original'),
            Tab(text: 'Compressed'),
          ],
        ),
        actions: [
          if (_isZoomed)
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () {
                setState(() {
                  _isZoomed = false;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Info card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'Original Size',
                      ImageUtils.formatFileSize(widget.originalSize),
                    ),
                    _buildStatColumn(
                      'Compressed Size',
                      ImageUtils.formatFileSize(widget.compressedSize),
                    ),
                    _buildStatColumn(
                      'Reduction',
                      '${reduction.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Compare view (slider)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isZoomed = !_isZoomed;
                    });
                  },
                  child: _isZoomed
                      ? _buildZoomedView()
                      : BeforeAfter(
                          before: Image.file(
                            File(widget.originalPath),
                            fit: BoxFit.contain,
                          ),
                          after: Image.file(
                            File(widget.compressedPath),
                            fit: BoxFit.contain,
                          ),
                          thumbColor: AppTheme.primaryColor,
                          thumbWidth: 30.0,
                          overlayColor: WidgetStateProperty.all<Color?>(Colors.black12),
                        ),
                ),
                
                // Original view
                _buildImageView(widget.originalPath),
                
                // Compressed view
                _buildImageView(widget.compressedPath),
              ],
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveToGallery,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareImage,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Ad banner
          //_buildAdBanner(),
        ],
      ),
    );
  }

  Widget _buildImageView(String path) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isZoomed = !_isZoomed;
        });
      },
      child: _isZoomed
          ? PhotoView(
              imageProvider: FileImage(File(path)),
              backgroundDecoration: const BoxDecoration(color: Colors.white),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            )
          : Image.file(
              File(path),
              fit: BoxFit.contain,
            ),
    );
  }

  Widget _buildZoomedView() {
    return Stack(
      children: [
        PhotoView(
          imageProvider: FileImage(File(_tabController.index == 1 
              ? widget.originalPath 
              : widget.compressedPath)),
          backgroundDecoration: const BoxDecoration(color: Colors.white),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
        const Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Pinch to zoom in/out',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
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

  // Widget _buildAdBanner() {
  //   if (AppConstants.enableAds && _isAdLoaded && _bannerAd != null) {
  //     return AdBanner(ad: _bannerAd!);
  //   } else {
  //     return const SizedBox.shrink();
  //   }
  // }
}