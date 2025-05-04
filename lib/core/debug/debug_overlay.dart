import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photoshrink/core/constants/debug_constants.dart';
import 'package:photoshrink/core/utils/logger_util.dart';

/// A debug overlay that can be displayed on top of the app
/// to show logs, performance metrics, and other debug info.
class DebugOverlay extends StatefulWidget {
  final Widget child;
  
  const DebugOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  static const String TAG = 'DebugOverlay';
  
  bool _showOverlay = false;
  List<LogEntry> _logEntries = [];
  final ScrollController _scrollController = ScrollController();
  final int _maxLogEntries = 100;
  StreamSubscription? _logSubscription;
  
  // Performance metrics
  int _frameCount = 0;
  double _fps = 0;
  Timer? _fpsTimer;
  
  @override
  void initState() {
    super.initState();
    LoggerUtil.d(TAG, 'Debug overlay initialized');
    
    // Subscribe to log stream (this is a placeholder, actual implementation would differ)
    // In a real app, you'd implement a way to capture all logs
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), _updateFPS);
  }
  
  void _updateFPS(Timer timer) {
    if (!_showOverlay) return;
    
    setState(() {
      _fps = _frameCount.toDouble();
      _frameCount = 0;
    });
  }
  
  void _toggleOverlay() {
    LoggerUtil.d(TAG, 'Toggling debug overlay: ${!_showOverlay}');
    
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }
  
  void _addLogEntry(LogEntry entry) {
    setState(() {
      _logEntries.add(entry);
      if (_logEntries.length > _maxLogEntries) {
        _logEntries.removeAt(0);
      }
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }
  
  void _clearLogs() {
    setState(() {
      _logEntries.clear();
    });
  }
  
  @override
  void dispose() {
    _logSubscription?.cancel();
    _fpsTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Count frame for FPS calculation
    _frameCount++;
    
    // This gesture detector is for double tap to toggle the debug overlay
    return GestureDetector(
      onDoubleTap: () => _toggleOverlay(),
      child: Directionality(
        // Add Directionality widget to fix the error
        textDirection: TextDirection.ltr,
        child: Stack(
          // Explicitly specify alignment to avoid issues
          alignment: Alignment.topLeft,
          children: [
            // Main app content
            widget.child,
            
            // Debug overlay (only shown when _showOverlay is true)
            if (_showOverlay)
              Material(
                type: MaterialType.transparency,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Debug overlay header
                      _buildOverlayHeader(),
                      
                      // Performance metrics
                      _buildPerformanceMetrics(),
                      
                      // Log entries
                      Expanded(
                        child: _buildLogList(),
                      ),
                      
                      // Controls
                      _buildControls(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverlayHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text(
            'PhotoShrink Debug',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            'v${DebugConstants.APP_VERSION}',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _toggleOverlay,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceMetrics() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildMetricCard('FPS', _fps.toStringAsFixed(1), 
              _fps < 30 ? Colors.red : Colors.green),
          _buildMetricCard('Memory', '?? MB', Colors.yellow),
          _buildMetricCard('Blocs', '??', Colors.blue),
        ],
      ),
    );
  }
  
  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: Colors.black45,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogList() {
    if (_logEntries.isEmpty) {
      return const Center(
        child: Text(
          'No logs yet',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      itemCount: _logEntries.length,
      itemBuilder: (context, index) {
        final entry = _logEntries[index];
        return _LogEntryWidget(entry: entry);
      },
    );
  }
  
  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildControlButton(Icons.clear_all, 'Clear', _clearLogs),
        _buildControlButton(
            Icons.bug_report, 'Add Log', () => _addSampleLog()),
        _buildControlButton(Icons.save, 'Save Logs', () {}),
      ],
    );
  }
  
  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  void _addSampleLog() {
    final logTypes = ['INFO', 'DEBUG', 'ERROR', 'WARNING'];
    final tags = ['HomeBloc', 'SettingsBloc', 'CompressionService', 'StorageService'];
    
    final type = logTypes[DateTime.now().millisecond % logTypes.length];
    final tag = tags[DateTime.now().second % tags.length];
    final message = 'Sample log message #${DateTime.now().millisecondsSinceEpoch % 1000}';
    
    _addLogEntry(LogEntry(
      level: type,
      tag: tag,
      message: message,
      timestamp: DateTime.now(),
    ));
  }
}

class LogEntry {
  final String level;
  final String tag;
  final String message;
  final DateTime timestamp;
  
  LogEntry({
    required this.level,
    required this.tag,
    required this.message,
    required this.timestamp,
  });
  
  Color get color {
    switch (level) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.yellow;
      case 'INFO':
        return Colors.blue;
      case 'DEBUG':
        return Colors.green;
      default:
        return Colors.white;
    }
  }
}

class _LogEntryWidget extends StatelessWidget {
  final LogEntry entry;
  
  const _LogEntryWidget({
    Key? key,
    required this.entry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Log level indicator
          Container(
            width: 3,
            height: 20,
            color: entry.color,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          
          // Timestamp
          Text(
            _formatTime(entry.timestamp),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: entry.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '[${entry.tag}]',
              style: TextStyle(
                color: entry.color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Message
          Expanded(
            child: Text(
              entry.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}