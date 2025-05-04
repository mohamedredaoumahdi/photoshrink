import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path/path.dart' as path_util;
import 'package:photoshrink/core/constants/debug_constants.dart';

/// Enhanced utility class for logging with better formatting and organization.
class LoggerUtil {
  // Log level enum
  static const int VERBOSE = 0;  // Most detailed, shows everything
  static const int DEBUG = 1;    // Development info
  static const int INFO = 2;     // Important but normal events
  static const int WARNING = 3;  // Potential issues
  static const int ERROR = 4;    // Error conditions
  static const int NONE = 5;     // No logging

  // ANSI color codes for console output
  static const String _resetColor = '\x1B[0m';
  static const String _redColor = '\x1B[31m';
  static const String _greenColor = '\x1B[32m';
  static const String _yellowColor = '\x1B[33m';
  static const String _blueColor = '\x1B[34m';
  static const String _magentaColor = '\x1B[35m';
  static const String _cyanColor = '\x1B[36m';
  static const String _whiteColor = '\x1B[37m';
  static const String _brightRedColor = '\x1B[91m';
  static const String _brightGreenColor = '\x1B[92m';
  static const String _brightYellowColor = '\x1B[93m';
  static const String _brightBlueColor = '\x1B[94m';
  static const String _brightMagentaColor = '\x1B[95m';
  static const String _brightCyanColor = '\x1B[96m';
  static const String _brightWhiteColor = '\x1B[97m';
  static const String _boldText = '\x1B[1m';
  static const String _italicText = '\x1B[3m';
  static const String _underlineText = '\x1B[4m';

  // Current log level
  static int _currentLogLevel = kDebugMode ? VERBOSE : INFO;
  
  // Performance tracking
  static final Map<String, DateTime> _operationStartTimes = {};
  
  // Operation stack for nested operations
  static final List<String> _operationStack = [];

  /// Configure the minimum log level
  static void setLogLevel(int level) {
    _currentLogLevel = level;
    i('LoggerUtil', 'Log level set to: ${_getLevelName(level)}');
  }
  
  // Get log level name
  static String _getLevelName(int level) {
    switch (level) {
      case VERBOSE: return 'VERBOSE';
      case DEBUG: return 'DEBUG';
      case INFO: return 'INFO';
      case WARNING: return 'WARNING';
      case ERROR: return 'ERROR';
      default: return 'UNKNOWN';
    }
  }

  /// Verbose level logging (most detailed)
  static void v(String tag, String message) {
    if (_currentLogLevel <= VERBOSE) {
      _log('VERBOSE', tag, message, _magentaColor);
    }
  }

  /// Debug level logging
  static void d(String tag, String message) {
    if (_currentLogLevel <= DEBUG) {
      _log('DEBUG', tag, message, _greenColor);
    }
  }

  /// Info level logging
  static void i(String tag, String message) {
    if (_currentLogLevel <= INFO) {
      _log('INFO', tag, message, _blueColor);
    }
  }

  /// Warning level logging
  static void w(String tag, String message) {
    if (_currentLogLevel <= WARNING) {
      _log('WARNING', tag, message, _yellowColor);
    }
  }

  /// Error level logging
  static void e(String tag, String message) {
    if (_currentLogLevel <= ERROR) {
      _log('ERROR', tag, message, _brightRedColor);
    }
  }

  /// BLoC event logging
  static void blocEvent(String blocName, String event) {
    if (_currentLogLevel <= DEBUG) {
      _log('BLOC', blocName, '📥 Event: $event', _cyanColor);
    }
  }

  /// BLoC state transition logging
  static void blocState(String blocName, String oldState, String newState) {
    if (_currentLogLevel <= DEBUG) {
      _log('BLOC', blocName, '📝 State: $oldState ➡️ $newState', _cyanColor);
    }
  }

  /// Service operation logging
  static void service(String serviceName, String operation, {bool isSuccess = true}) {
    if (_currentLogLevel <= DEBUG) {
      final status = isSuccess ? '✅' : '❌';
      _log('SERVICE', serviceName, '$status $operation', _whiteColor);
    }
  }

  /// API call logging
  static void api(String endpoint, String method, int statusCode) {
    if (_currentLogLevel <= DEBUG) {
      final color = (statusCode >= 200 && statusCode < 300) ? _greenColor : _redColor;
      _log('API', endpoint, '$method - Status: $statusCode', color);
    }
  }
  
  /// UI rendering logging
  static void ui(String widgetName, String action) {
    if (_currentLogLevel <= DEBUG && DebugConstants.LOG_NAVIGATION) {
      _log('UI', widgetName, action, _brightMagentaColor);
    }
  }
  
  /// Navigation logging
  static void navigation(String routeName, {String? args}) {
    if (_currentLogLevel <= DEBUG && DebugConstants.LOG_NAVIGATION) {
      final String message = args != null ? 'Navigating to $routeName with args: $args' : 'Navigating to $routeName';
      _log('NAVIGATION', 'Router', message, _brightYellowColor);
    }
  }
  
  /// File operation logging
  static void file(String operation, String filePath, {int? size}) {
    if (_currentLogLevel <= DEBUG && DebugConstants.LOG_FILE_OPERATIONS) {
      String message = '$operation: ${truncatePath(filePath)}';
      if (size != null) {
        message += ' (${_formatSize(size)})';
      }
      _log('FILE', 'FileIO', message, _brightBlueColor);
    }
  }
  
  /// Start tracking an operation
  static void startOperation(String operationName) {
    if (!DebugConstants.LOG_PERFORMANCE) return;
    
    _operationStartTimes[operationName] = DateTime.now();
    _operationStack.add(operationName);
    
    if (_currentLogLevel <= DEBUG) {
      _log('PERFORMANCE', 'Timer', '⏱️ Started: $operationName', _whiteColor);
    }
  }
  
  /// End tracking an operation and log its duration
  static void endOperation(String operationName) {
    if (!DebugConstants.LOG_PERFORMANCE) return;
    
    final startTime = _operationStartTimes[operationName];
    if (startTime == null) {
      w('LoggerUtil', 'Cannot end operation $operationName: never started');
      return;
    }
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;
    
    if (_operationStack.isNotEmpty && _operationStack.last == operationName) {
      _operationStack.removeLast();
    }
    
    _operationStartTimes.remove(operationName);
    
    final String durationStr = _formatDuration(duration);
    final bool isSlow = duration > DebugConstants.SLOW_OPERATION_THRESHOLD;
    
    if (_currentLogLevel <= DEBUG) {
      final String icon = isSlow ? '⚠️ Slow' : '✓ Done';
      final String message = '$icon: $operationName took $durationStr';
      
      if (isSlow) {
        _log('PERFORMANCE', 'Timer', message, _redColor);
      } else {
        _log('PERFORMANCE', 'Timer', message, _whiteColor);
      }
    }
  }

  /// Log a section header
  static void startSection(String title) {
    if (_currentLogLevel <= INFO) {
      debugPrint('\n${DebugConstants.SECTION_START}');
      debugPrint('${DebugConstants.SECTION_MIDDLE} ${_boldText}${_underlineText}$title${_resetColor}');
    }
  }
  
  /// Log a section footer
  static void endSection(String summary) {
    if (_currentLogLevel <= INFO) {
      debugPrint('${DebugConstants.SECTION_MIDDLE} $summary');
      debugPrint('${DebugConstants.SECTION_END}\n');
    }
  }

  /// Truncate file paths for readability
  static String truncatePath(String filePath) {
    try {
      if (filePath.isEmpty) return filePath;
      
      final filename = path_util.basename(filePath);
      // Display only the last 2 directories in the path plus filename
      final dirs = path_util.dirname(filePath).split(Platform.pathSeparator);
      
      if (dirs.length <= 2) return filePath;
      
      final lastDirs = dirs.sublist(dirs.length - 2);
      return '...${Platform.pathSeparator}${lastDirs.join(Platform.pathSeparator)}${Platform.pathSeparator}$filename';
    } catch (e) {
      return filePath; // If there's an error in parsing, return the original
    }
  }
  
  /// Format file size for logging
  static String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
  
  /// Format duration for performance logging
  static String _formatDuration(int milliseconds) {
    if (milliseconds < 1000) {
      return '$milliseconds ms';
    } else {
      final seconds = (milliseconds / 1000).toStringAsFixed(2);
      return '$seconds s';
    }
  }

  /// Internal logging method with enhanced formatting
  static void _log(String level, String tag, String message, String color) {
    final timestamp = DateTime.now().toString().split('.').first;
    
    // Format prefix based on log level
    String prefix;
    switch (level) {
      case 'BLOC':
        prefix = DebugConstants.BLOC_PREFIX;
        break;
      case 'SERVICE':
        prefix = DebugConstants.SERVICE_PREFIX;
        break;
      case 'API':
        prefix = DebugConstants.API_PREFIX;
        break;
      case 'FILE':
        prefix = DebugConstants.FILE_PREFIX;
        break;
      case 'NAVIGATION':
        prefix = DebugConstants.UI_PREFIX;
        break;
      case 'ERROR':
        prefix = DebugConstants.ERROR_PREFIX;
        break;
      default:
        prefix = DebugConstants.APP_PREFIX;
    }
    
    // Add nesting indentation for stack-based operations
    String indentation = '';
    if (_operationStack.isNotEmpty && level == 'PERFORMANCE') {
      indentation = '  ' * (_operationStack.length - 1);
    }
    
    // Format the full log message with color coding and structure
    final formattedMessage = '$color[$timestamp] $prefix [$level] [$tag] $indentation$message$_resetColor';
    
    // Print to console
    debugPrint(formattedMessage);
  }
  
  /// Log memory usage
  static void logMemoryUsage() {
    if (_currentLogLevel <= DEBUG && DebugConstants.LOG_PERFORMANCE) {
      // Note: Memory info is not directly available in Flutter, so we log this as a placeholder
      _log('PERFORMANCE', 'Memory', '🧠 Memory usage stats would appear here', _yellowColor);
    }
  }
  
  /// Log a key-value pair for configuration
  static void config(String key, dynamic value) {
    if (_currentLogLevel <= INFO) {
      _log('CONFIG', 'AppConfig', '⚙️ $key = $value', _brightGreenColor);
    }
  }
  
  /// Collapse long lists in logs
  static String formatList(List items, {int maxItems = 3}) {
    if (items.isEmpty) {
      return '[]';
    }
    
    if (items.length <= maxItems) {
      return items.toString();
    }
    
    final first = items.take(maxItems).join(', ');
    return '[$first, ... and ${items.length - maxItems} more]';
  }
  
  /// Log an object with pretty formatting
  static void object(String tag, String objectName, dynamic object) {
    if (_currentLogLevel <= DEBUG) {
      _log('OBJECT', tag, '📦 $objectName: ${_formatObject(object)}', _brightCyanColor);
    }
  }
  
  /// Format object for logging
  static String _formatObject(dynamic object) {
    if (object is List) {
      return formatList(object);
    } else if (object is Map) {
      return '{${object.entries.map((e) => '${e.key}: ${_formatObject(e.value)}').join(', ')}}';
    } else {
      return object.toString();
    }
  }
}