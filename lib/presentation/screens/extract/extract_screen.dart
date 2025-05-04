import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_bloc.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_event.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_state.dart';

class ExtractScreen extends StatefulWidget {
  final String archivePath;

  const ExtractScreen({
    Key? key,
    required this.archivePath,
  }) : super(key: key);

  @override
  State<ExtractScreen> createState() => _ExtractScreenState();
}

class _ExtractScreenState extends State<ExtractScreen> {
  final CompressionBloc _compressionBloc = getIt<CompressionBloc>();
  bool _saveToGallery = true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _compressionBloc,
      child: BlocConsumer<CompressionBloc, CompressionState>(
        listener: (context, state) {
          if (state is ExtractionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is ExtractionSuccess) {
            // Show success dialog
            _showSuccessDialog(context, state.count);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Extract Archive'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildBody(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CompressionState state) {
    if (state is ExtractionInProgress) {
      return _buildProgressView(state);
    } else if (state is ExtractionSuccess) {
      return _buildSuccessView(state);
    } else {
      return _buildInitialView();
    }
  }

  Widget _buildInitialView() {
    final fileName = path.basename(widget.archivePath);
    final fileSize = File(widget.archivePath).lengthSync();
    final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2,
            size: 72,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          Text(
            'Archive: $fileName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'Size: $fileSizeMB MB',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          const Text(
            'This archive contains images in their original quality. Extracting will restore them exactly as they were when archived.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Save to Gallery'),
            subtitle: const Text('Images will be saved to your photo gallery'),
            value: _saveToGallery,
            onChanged: (value) {
              setState(() {
                _saveToGallery = value;
              });
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _compressionBloc.add(ExtractArchiveEvent(
                archivePath: widget.archivePath,
                saveToGallery: _saveToGallery,
              ));
            },
            icon: const Icon(Icons.unarchive),
            label: const Text('Extract Images'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressView(ExtractionInProgress state) {
    final progress = state.progress;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Extracting Images...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${state.processedImages} of ${state.totalImages}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          const Text(
            'Please wait while your original quality images are being extracted...',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessView(ExtractionSuccess state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 72,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            '${state.count} Images Extracted!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All images have been successfully extracted in their original quality.',
            textAlign: TextAlign.center,
          ),
          if (_saveToGallery)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Images have been saved to your gallery.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSuccessDialog(BuildContext context, int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: Text(
          '$count images were successfully extracted with original quality${_saveToGallery ? ' and saved to your gallery' : ''}.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}