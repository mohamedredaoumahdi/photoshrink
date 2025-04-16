import 'package:firebase_analytics/firebase_analytics.dart';

abstract class AnalyticsService {
  Future<void> logEvent(String name, Map<String, dynamic> parameters);
  Future<void> logSelectContent({required String contentType, required String itemId});
  Future<void> logCompression({required int imageCount, required int quality, required double sizeReduction});
  Future<void> logSubscriptionPurchase({required String planId, required double price});
  Future<void> setUserProperties({required String userId, required bool isPremium});
}

class AnalyticsServiceImpl implements AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> logSelectContent({required String contentType, required String itemId}) async {
    await _analytics.logSelectContent(contentType: contentType, itemId: itemId);
  }

  @override
  Future<void> logCompression({
    required int imageCount, 
    required int quality, 
    required double sizeReduction
  }) async {
    await _analytics.logEvent(
      name: 'image_compression',
      parameters: {
        'image_count': imageCount,
        'quality': quality,
        'size_reduction': sizeReduction,
      },
    );
  }

  @override
  Future<void> logSubscriptionPurchase({
    required String planId, 
    required double price
  }) async {
    await _analytics.logEvent(
      name: 'subscription_purchase',
      parameters: {
        'plan_id': planId,
        'price': price,
      },
    );
  }

  @override
  Future<void> setUserProperties({
    required String userId, 
    required bool isPremium
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'is_premium', value: isPremium.toString());
  }
}