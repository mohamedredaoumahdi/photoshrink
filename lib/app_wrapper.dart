import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoshrink/core/constants/debug_constants.dart';
import 'package:photoshrink/core/debug/debug_overlay.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:photoshrink/main.dart';

/// A wrapper for the main app that adds debugging features
class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  static const String TAG = 'AppWrapper';
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  DateTime? _appStartTime;
  DateTime? _lastResumeTime;
  
  @override
  void initState() {
    super.initState();
    _appStartTime = DateTime.now();
    
    // Register as an observer to track app lifecycle
    WidgetsBinding.instance.addObserver(this);
    
    LoggerUtil.startSection('App Launch');
    LoggerUtil.i(TAG, '🚀 AppWrapper initialized');
    
    // Log device info and app configuration
    _logAppInfo();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _lastResumeTime = DateTime.now();
        LoggerUtil.i(TAG, '▶️ App resumed');
        break;
      case AppLifecycleState.inactive:
        LoggerUtil.i(TAG, '⏸️ App inactive');
        break;
      case AppLifecycleState.paused:
        LoggerUtil.i(TAG, '⏸️ App paused');
        if (_lastResumeTime != null) {
          final sessionDuration = DateTime.now().difference(_lastResumeTime!);
          LoggerUtil.i(TAG, '📊 Session duration: ${_formatDuration(sessionDuration)}');
        }
        break;
      case AppLifecycleState.detached:
        LoggerUtil.i(TAG, '⏹️ App detached');
        break;
      default:
        LoggerUtil.d(TAG, 'App lifecycle state changed: $state');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    if (_appStartTime != null) {
      final appRuntime = DateTime.now().difference(_appStartTime!);
      LoggerUtil.i(TAG, '📊 Total app runtime: ${_formatDuration(appRuntime)}');
    }
    
    LoggerUtil.endSection('App Termination');
    super.dispose();
  }
  
  void _logAppInfo() {
    // This would ideally include device info, platform version, etc.
    // but for simplicity, we'll just log basic info
    LoggerUtil.config('APP_VERSION', DebugConstants.APP_VERSION);
    LoggerUtil.config('DEBUG_MODE', kDebugMode);
    LoggerUtil.config('VERBOSE_LOGGING', DebugConstants.VERBOSE_LOGGING);
    LoggerUtil.config('LOG_PERFORMANCE', DebugConstants.LOG_PERFORMANCE);
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    // We need to wrap our app in a MaterialApp or at least a Directionality
    // widget to provide the directionality context for our debug overlay
    return MaterialApp(
      // Use a builder to get access to a BuildContext with MediaQuery information
      // This allows us to layer the debug overlay on top of the app
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          return DebugOverlay(
            child: PhotoShrinkApp(
              navigatorKey: _navigatorKey,
            ),
          );
        }
      ),
    );
  }
}