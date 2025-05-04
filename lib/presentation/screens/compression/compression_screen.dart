import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photoshrink/core/utils/image_utils.dart';
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_bloc.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_event.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_state.dart';
import 'package:photoshrink/presentation/screens/compression/widgets/compression_progress.dart';
import 'package:photoshrink/services/archive/archive_service.dart';

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
  final ArchiveService _archiveService = ArchiveService();

  @override
  void initState() {
    super.initState();
    
    // Start archiving process
    _compressionBloc.add(StartCompressionProcess(
      imagePaths: widget.imagePaths,
    ));
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
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Creating Archive'),
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
      return _buildArchivingResults(context, state);
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Widget _buildArchivingResults(BuildContext context, CompressionSuccess state) {
    final result = state.results[0]; // We only have one result - the archive
    final sizeBefore = ImageUtils.formatFileSize(state.originalTotalSize);
    final sizeAfter = ImageUtils.formatFileSize(state.compressedTotalSize);
    
    // Wrap everything in a SingleChildScrollView to prevent overflow
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Card
            Card(
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
                    const Text(
                      'Archive Created Successfully!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.imagePaths.length} images bundled with original quality',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Size comparison
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn(
                          'Original Size',
                          sizeBefore,
                          Icons.photo_library,
                        ),
                        const Icon(Icons.arrow_forward),
                        _buildInfoColumn(
                          'Archive Size',
                          sizeAfter,
                          Icons.inventory_2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Reduction info
                    Text(
                      'Reduced file size by ${state.totalReduction.toStringAsFixed(1)}% without quality loss!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text(
                      'The archive file contains all your images in their original quality. Recipients must use PhotoShrink to extract them.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            ElevatedButton.icon(
              onPressed: () {
                _shareArchive(result.compressedPath);
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Archive'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            
            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.check),
              label: const Text('Done'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareArchive(String archivePath) async {
    try {
      final file = File(archivePath);
      final bool success = await _archiveService.shareArchive(
        file,
        message: 'This file contains high-quality images shared from PhotoShrink. Open with PhotoShrink to extract them.',
      );
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share the archive. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}