import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photoshrink/core/constants/debug_constants.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:photoshrink/core/utils/performance_utils.dart';

/// Examples of how to use the debugging tools in the app
/// This class is only meant for illustration purposes
class DebugExamples {
  static const String TAG = 'DebugExamples';
  
  /// Example of how to use the LoggerUtil for different log levels
  static void loggerExample() {
    LoggerUtil.v(TAG, 'This is a verbose log message (most detailed)');
    LoggerUtil.d(TAG, 'This is a debug log message');
    LoggerUtil.i(TAG, 'This is an info log message');
    LoggerUtil.w(TAG, 'This is a warning log message');
    LoggerUtil.e(TAG, 'This is an error log message');
    
    // Bloc events and states
    LoggerUtil.blocEvent('ExampleBloc', 'ExampleEvent');
    LoggerUtil.blocState('ExampleBloc', 'InitialState', 'LoadingState');
    
    // Service operations
    LoggerUtil.service('ExampleService', 'fetchData', isSuccess: true);
    LoggerUtil.service('ExampleService', 'saveData', isSuccess: false);
    
    // API calls
    LoggerUtil.api('/api/users', 'GET', 200);
    LoggerUtil.api('/api/login', 'POST', 401);
    
    // Section logging
    LoggerUtil.startSection('Example Section');
    LoggerUtil.i(TAG, 'This is inside a section');
    LoggerUtil.endSection('Section complete');
    
    // File operations
    LoggerUtil.file('read', '/path/to/file.jpg', size: 1024 * 1024);
    LoggerUtil.file('write', '/path/to/output.jpg', size: 512 * 1024);
    
    // Performance operations
    LoggerUtil.startOperation('example_operation');
    // Do something...
    LoggerUtil.endOperation('example_operation');
    
    // Object logging
    final exampleObject = {
      'id': 123,
      'name': 'Example',
      'items': [1, 2, 3, 4, 5],
    };
    LoggerUtil.object(TAG, 'exampleObject', exampleObject);
    
    // List formatting
    final longList = List.generate(100, (index) => index);
    LoggerUtil.d(TAG, 'Long list: ${LoggerUtil.formatList(longList)}');
  }
  
  /// Example of how to use the PerformanceUtils for measuring execution time
  static Future<void> performanceExample() async {
    // Measuring asynchronous operations
    final result = await PerformanceUtils.measure(
      'async_operation',
      () async {
        // Simulate an async operation
        await Future.delayed(const Duration(milliseconds: 500));
        return 'Result';
      },
    );
    
    // Measuring synchronous operations
    final syncResult = PerformanceUtils.measureSync(
      'sync_operation',
      () {
        // Simulate a sync operation
        int sum = 0;
        for (int i = 0; i < 1000000; i++) {
          sum += i;
        }
        return sum;
      },
    );
    
    // Manual measurement
    final stopwatch = PerformanceUtils.start('manual_operation');
    // Do something...
    await Future.delayed(const Duration(milliseconds: 300));
    PerformanceUtils.end('manual_operation', stopwatch);
    
    // Get metrics for a specific operation
    final metrics = PerformanceUtils.getMetricForOperation('async_operation');
    if (metrics != null) {
      LoggerUtil.d(TAG, 'Metrics for async_operation: $metrics');
    }
  }
  
  /// Example of how to properly log UI-related events
  static void uiLoggingExample(BuildContext context) {
    // Log navigation
    LoggerUtil.navigation('/home');
    
    // Log UI rendering
    LoggerUtil.ui('HomeScreen', 'Building widget');
    
    // Log button clicks
    void onButtonPressed() {
      LoggerUtil.ui('HomeScreen', 'Button pressed');
      // Do something...
    }
    
    // Log screen transitions
    void navigateToSettings() {
      LoggerUtil.ui('HomeScreen', 'Navigating to settings');
      Navigator.of(context).pushNamed('/settings');
    }
  }
  
  /// Example of how to properly format file paths in logs
  static void filePathExample() {
    final longPath = '/Users/username/Documents/Projects/PhotoShrink/assets/images/example.jpg';
    final truncatedPath = LoggerUtil.truncatePath(longPath);
    LoggerUtil.d(TAG, 'Original path: $longPath');
    LoggerUtil.d(TAG, 'Truncated path: $truncatedPath');
  }
  
  /// Example of how to use LoggerUtil to debug complex operations
  static Future<void> debugComplexOperationExample() async {
    LoggerUtil.startSection('Complex Operation');
    LoggerUtil.i(TAG, 'Starting complex operation');
    
    // Let's simulate multiple stages of a complex operation
    
    // Stage 1: Initialize
    LoggerUtil.startOperation('stage1_initialize');
    await Future.delayed(const Duration(milliseconds: 200));
    LoggerUtil.d(TAG, 'Stage 1 completed');
    LoggerUtil.endOperation('stage1_initialize');
    
    // Stage 2: Load data
    LoggerUtil.startOperation('stage2_load_data');
    try {
      // Simulate loading data with occasional errors
      if (DateTime.now().millisecond % 5 == 0) {
        throw Exception('Simulated random error');
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
      LoggerUtil.d(TAG, 'Stage 2 completed');
      LoggerUtil.endOperation('stage2_load_data');
      
      // Stage 3: Process data
      LoggerUtil.startOperation('stage3_process_data');
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Log some processing statistics
      final processingStats = {
        'processed_items': 42,
        'skipped_items': 3,
        'duration_ms': 387,
      };
      LoggerUtil.object(TAG, 'processingStats', processingStats);
      
      LoggerUtil.d(TAG, 'Stage 3 completed');
      LoggerUtil.endOperation('stage3_process_data');
      
      // Stage 4: Save results
      LoggerUtil.startOperation('stage4_save_results');
      await Future.delayed(const Duration(milliseconds: 250));
      LoggerUtil.d(TAG, 'Stage 4 completed');
      LoggerUtil.endOperation('stage4_save_results');
      
      LoggerUtil.i(TAG, 'Complex operation completed successfully');
    } catch (e) {
      LoggerUtil.e(TAG, 'Error during complex operation: $e');
      // End any active operations
      LoggerUtil.endOperation('stage2_load_data');
    }
    
    LoggerUtil.endSection('Complex Operation Complete');
  }
  
  /// Example of how to log configuration and debug flags
  static void logConfigurationExample() {
    LoggerUtil.config('ENABLE_CLOUD_STORAGE', DebugConstants.LOG_FILE_OPERATIONS);
    LoggerUtil.config('VERBOSE_LOGGING', DebugConstants.VERBOSE_LOGGING);
    LoggerUtil.config('SLOW_OPERATION_THRESHOLD', '${DebugConstants.SLOW_OPERATION_THRESHOLD}ms');
  }
}