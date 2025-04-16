class AppConstants {
  // App info
  static const String appName = 'PhotoShrink';
  static const String appVersion = '1.0.0';
  
  // Compression levels
  static const int highQuality = 80;
  static const int mediumQuality = 60;
  static const int lowQuality = 40;
  
  // Storage keys
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String userSettingsKey = 'user_settings';
  static const String compressionHistoryKey = 'compression_history';
  static const String defaultCompressionLevelKey = 'default_compression_level';
  
  // Subscription plans
  static const String monthlySubscriptionId = 'photoshrink_premium_monthly';
  static const String yearlySubscriptionId = 'photoshrink_premium_yearly';
  
  // Ad units (replace with actual ad unit IDs)
  static const String bannerAdUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
  
  // Cloud storage paths
  static const String cloudStorageBasePath = 'compressed_images';
  
  // Result messages
  static const String compressionSuccessMessage = 'Image(s) compressed successfully!';
  static const String compressionFailureMessage = 'Failed to compress the image(s). Please try again.';
  static const String savingSuccessMessage = 'Image saved to gallery!';
  static const String savingFailureMessage = 'Failed to save the image. Please try again.';
  static const String shareSuccessMessage = 'Image shared successfully!';
  static const String noImagesSelectedMessage = 'Please select at least one image.';
  
  // Feature flags
  static const bool enableCloudStorage = true;
  static const bool enableUserAuthentication = true;
  static const bool enableAds = true;
  static const bool enableAnalytics = true;
}