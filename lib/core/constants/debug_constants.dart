/// Constants and settings for debugging
class DebugConstants {
  // Current app version - useful for log filtering
  static const String APP_VERSION = '1.0.0';
  
  // Debug prefixes for easier identification in logs
  static const String APP_PREFIX = '📱 PhotoShrink';
  static const String BLOC_PREFIX = '🔄 Bloc';
  static const String SERVICE_PREFIX = '🔧 Service';
  static const String UI_PREFIX = '🎨 UI';
  static const String FILE_PREFIX = '📁 File';
  static const String API_PREFIX = '🌐 API';
  static const String AUTH_PREFIX = '🔐 Auth';
  static const String PURCHASE_PREFIX = '💰 Purchase';
  static const String ERROR_PREFIX = '⚠️ ERROR';
  
  // Log section separators for important operations
  static const String SECTION_START = '┌──────────────────────────────────────────────────────';
  static const String SECTION_END =   '└──────────────────────────────────────────────────────';
  static const String SECTION_MIDDLE = '│';
  
  // Debug flags - can be toggled to enable/disable various debug features
  static bool VERBOSE_LOGGING = true;
  static bool LOG_PERFORMANCE = true;
  static bool LOG_NAVIGATION = true;
  static bool LOG_FILE_OPERATIONS = true;
  static bool LOG_NETWORK_CALLS = true;
  static bool LOG_STATE_CHANGES = true;
  
  // Performance thresholds for warning logs (in milliseconds)
  static const int SLOW_OPERATION_THRESHOLD = 1000; // 1 second
  static const int UI_LAG_THRESHOLD = 16; // 16ms (60 fps)
  
  // Maximum file path length for truncated paths in logs
  static const int MAX_PATH_LENGTH = 50;
}