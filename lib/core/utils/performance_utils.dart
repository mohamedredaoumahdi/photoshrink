import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:photoshrink/core/constants/debug_constants.dart';
import 'package:photoshrink/core/utils/logger_util.dart';

/// Utility class for performance monitoring in the app
class PerformanceUtils {
  static const String TAG = 'Performance';
  
  // Stores performance metrics by operation name
  static final Map<String, PerformanceMetric> _metrics = {};
  
  // Timer for periodically logging performance stats
  static Timer? _statsTimer;
  
  /// Initialize performance monitoring
  static void init() {
    if (!DebugConstants.LOG_PERFORMANCE) return;
    
    LoggerUtil.i(TAG, 'Performance monitoring initialized');
    
    // Set up a timer to log performance stats periodically
    _statsTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _logPerformanceStats();
    });
  }
  
  /// Dispose performance monitoring
  static void dispose() {
    _statsTimer?.cancel();
    _metrics.clear();
  }
  
  /// Measure the execution time of a function
  static Future<T> measure<T>(String operationName, Future<T> Function() function) async {
    if (!DebugConstants.LOG_PERFORMANCE) return function();
    
    final stopwatch = Stopwatch()..start();
    
    try {
      LoggerUtil.d(TAG, 'Starting operation: $operationName');
      final result = await function();
      stopwatch.stop();
      
      _recordMetric(operationName, stopwatch.elapsedMilliseconds);
      
      LoggerUtil.d(TAG, 'Completed operation: $operationName in ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordMetric(operationName, stopwatch.elapsedMilliseconds, isError: true);
      
      LoggerUtil.e(TAG, 'Error in operation: $operationName (${stopwatch.elapsedMilliseconds}ms) - $e');
      rethrow;
    }
  }
  
  /// Measure the execution time of a synchronous function
  static T measureSync<T>(String operationName, T Function() function) {
    if (!DebugConstants.LOG_PERFORMANCE) return function();
    
    final stopwatch = Stopwatch()..start();
    
    try {
      LoggerUtil.d(TAG, 'Starting sync operation: $operationName');
      final result = function();
      stopwatch.stop();
      
      _recordMetric(operationName, stopwatch.elapsedMilliseconds);
      
      LoggerUtil.d(TAG, 'Completed sync operation: $operationName in ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordMetric(operationName, stopwatch.elapsedMilliseconds, isError: true);
      
      LoggerUtil.e(TAG, 'Error in sync operation: $operationName (${stopwatch.elapsedMilliseconds}ms) - $e');
      rethrow;
    }
  }
  
  /// Start measuring an operation manually
  static Stopwatch start(String operationName) {
    if (!DebugConstants.LOG_PERFORMANCE) return Stopwatch();
    
    LoggerUtil.d(TAG, 'Starting manual operation: $operationName');
    return Stopwatch()..start();
  }
  
  /// End measuring an operation that was started manually
  static void end(String operationName, Stopwatch stopwatch) {
    if (!DebugConstants.LOG_PERFORMANCE) return;
    
    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;
    
    _recordMetric(operationName, elapsed);
    
    LoggerUtil.d(TAG, 'Completed manual operation: $operationName in ${elapsed}ms');
  }
  
  /// Record a performance metric
  static void _recordMetric(String operation, int durationMs, {bool isError = false}) {
    if (!_metrics.containsKey(operation)) {
      _metrics[operation] = PerformanceMetric(operation);
    }
    
    _metrics[operation]!.addSample(durationMs, isError: isError);
    
    // Log warnings for slow operations
    if (durationMs > DebugConstants.SLOW_OPERATION_THRESHOLD) {
      LoggerUtil.w(TAG, 'Slow operation: $operation took ${durationMs}ms');
    }
  }
  
  /// Log performance statistics
  static void _logPerformanceStats() {
    if (_metrics.isEmpty) return;
    
    LoggerUtil.startSection('Performance Stats');
    
    LoggerUtil.i(TAG, 'Performance statistics for ${_metrics.length} operations:');
    
    // Sort operations by average duration (slowest first)
    final sortedMetrics = _metrics.values.toList()
      ..sort((a, b) => b.averageDuration.compareTo(a.averageDuration));
    
    for (final metric in sortedMetrics) {
      LoggerUtil.i(TAG, metric.toString());
    }
    
    LoggerUtil.endSection('End Performance Stats');
  }
  
  /// Get performance metrics for a specific operation
  static PerformanceMetric? getMetricForOperation(String operationName) {
    return _metrics[operationName];
  }
  
  /// Get all performance metrics
  static List<PerformanceMetric> getAllMetrics() {
    return _metrics.values.toList();
  }
}

/// Represents performance metrics for an operation
class PerformanceMetric {
  final String operation;
  final List<int> _samples = [];
  int _errorCount = 0;
  int _slowCount = 0;
  
  PerformanceMetric(this.operation);
  
  void addSample(int durationMs, {bool isError = false}) {
    _samples.add(durationMs);
    
    if (isError) {
      _errorCount++;
    }
    
    if (durationMs > DebugConstants.SLOW_OPERATION_THRESHOLD) {
      _slowCount++;
    }
  }
  
  int get count => _samples.length;
  int get errorCount => _errorCount;
  int get slowCount => _slowCount;
  
  int get minDuration => _samples.isEmpty ? 0 : _samples.reduce((a, b) => a < b ? a : b);
  int get maxDuration => _samples.isEmpty ? 0 : _samples.reduce((a, b) => a > b ? a : b);
  
  double get averageDuration {
    if (_samples.isEmpty) return 0;
    return _samples.reduce((a, b) => a + b) / _samples.length;
  }
  
  double get errorRate {
    if (_samples.isEmpty) return 0;
    return _errorCount / _samples.length;
  }
  
  double get slowRate {
    if (_samples.isEmpty) return 0;
    return _slowCount / _samples.length;
  }
  
  @override
  String toString() {
    return '$operation: avg=${averageDuration.toStringAsFixed(1)}ms, min=${minDuration}ms, max=${maxDuration}ms, count=$count, errors=$errorCount, slow=$_slowCount';
  }
}