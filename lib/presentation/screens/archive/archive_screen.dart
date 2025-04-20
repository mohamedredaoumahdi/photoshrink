import 'package:flutter/material.dart';
import 'package:photoshrink/services/archive/archive_service.dart';

class ArchiveExtractScreen extends StatefulWidget {
  final String archivePath;
  
  const ArchiveExtractScreen({
    Key? key, 
    required this.archivePath,
  }) : super(key: key);
  
  @override
  State<ArchiveExtractScreen> createState() => _ArchiveExtractScreenState();
}

class _ArchiveExtractScreenState extends State<ArchiveExtractScreen> {
  final ArchiveService _archiveService = ArchiveService();
  bool _isExtracting = false;
  List<String> _extractedPaths = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extract Archive'),
      ),
      body: Center(
        child: _isExtracting 
          ? const CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_extractedPaths.isEmpty) ...[
                  const Text(
                    'Extract images from archive?',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _extractArchive,
                    child: const Text('Extract Images'),
                  ),
                ] else ...[
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_extractedPaths.length} images extracted to gallery',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ],
            ),
      ),
    );
  }
  
  Future<void> _extractArchive() async {
    setState(() {
      _isExtracting = true;
    });
    
    final extractedPaths = await _archiveService.extractArchive(widget.archivePath);
    
    setState(() {
      _isExtracting = false;
      _extractedPaths = extractedPaths;
    });
  }
}