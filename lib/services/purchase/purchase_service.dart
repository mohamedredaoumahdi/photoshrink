import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:photoshrink/data/models/subscription_plan.dart';

abstract class PurchaseService {
  Future<void> initialize();
  Future<bool> isPremiumUser();
  Future<List<SubscriptionPlan>> getAvailableSubscriptions();
  Future<bool> purchaseSubscription(String planId);
  Future<bool> restorePurchases();
  Stream<bool> get purchaseStatusStream;
  void dispose();
}

class PurchaseServiceImpl implements PurchaseService {
  static const String TAG = 'PurchaseService';
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final StreamController<bool> _purchaseStatusController = StreamController<bool>.broadcast();
  bool _isPremium = false;
  
  // Product IDs to query
  final Set<String> _productIds = {
    AppConstants.monthlySubscriptionId,
    AppConstants.yearlySubscriptionId,
  };
  
  PurchaseServiceImpl() {
    LoggerUtil.i(TAG, 'PurchaseService initialized');
  }
  
  @override
  Future<void> initialize() async {
    LoggerUtil.d(TAG, 'Initializing purchase service');
    LoggerUtil.startOperation('purchase_service_init');
    
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      LoggerUtil.w(TAG, 'In-app purchases are not available on this device');
      _isPremium = false;
      _purchaseStatusController.add(_isPremium);
      LoggerUtil.endOperation('purchase_service_init');
      return;
    }
    
    LoggerUtil.d(TAG, 'In-app purchases are available, setting up subscription');
    
    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        LoggerUtil.d(TAG, 'Purchase stream closed');
        _subscription?.cancel();
      },
      onError: (error) {
        LoggerUtil.e(TAG, 'Error in purchase stream: $error');
      },
    );
    
    // Load products
    await _loadProducts();
    
    // Check for existing purchases
    await restorePurchases();
    
    LoggerUtil.i(TAG, 'Purchase service initialization complete');
    LoggerUtil.endOperation('purchase_service_init');
  }
  
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      LoggerUtil.d(TAG, 'Purchase update received: ${purchaseDetails.productID} - Status: ${purchaseDetails.status}');
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        LoggerUtil.i(TAG, 'Purchase pending for ${purchaseDetails.productID}');
        // Show a dialog/loading indicator
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error case
        LoggerUtil.e(TAG, 'Purchase error for ${purchaseDetails.productID}: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Verify the purchase
        LoggerUtil.i(TAG, 'Purchase ${purchaseDetails.status == PurchaseStatus.restored ? "restored" : "completed"} for ${purchaseDetails.productID}');
        _verifyPurchase(purchaseDetails);
      }
      
      if (purchaseDetails.pendingCompletePurchase) {
        LoggerUtil.d(TAG, 'Completing pending purchase for ${purchaseDetails.productID}');
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  Future<void> _loadProducts() async {
    LoggerUtil.d(TAG, 'Loading products: ${_productIds.join(', ')}');
    LoggerUtil.startOperation('load_products');
    
    try {
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(_productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        LoggerUtil.w(TAG, 'Products not found: ${response.notFoundIDs.join(', ')}');
      }
      
      if (response.productDetails.isNotEmpty) {
        LoggerUtil.i(TAG, 'Loaded ${response.productDetails.length} products:');
        for (final product in response.productDetails) {
          LoggerUtil.d(TAG, '  - ${product.id}: ${product.title} (${product.price})');
        }
      } else {
        LoggerUtil.w(TAG, 'No products found');
      }
    } catch (e) {
      LoggerUtil.e(TAG, 'Error loading products: $e');
    } finally {
      LoggerUtil.endOperation('load_products');
    }
  }
  
  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    LoggerUtil.d(TAG, 'Verifying purchase: ${purchaseDetails.productID}');
    LoggerUtil.startOperation('verify_purchase');
    
    try {
      // Here you would typically validate the receipt with your server
      // For simplicity, we're just checking if it's one of our subscription IDs
      if (_productIds.contains(purchaseDetails.productID)) {
        LoggerUtil.i(TAG, 'Purchase verified: Premium subscription activated');
        _isPremium = true;
        _purchaseStatusController.add(_isPremium);
      } else {
        LoggerUtil.w(TAG, 'Unknown product ID: ${purchaseDetails.productID}');
      }
    } catch (e) {
      LoggerUtil.e(TAG, 'Error verifying purchase: $e');
    } finally {
      LoggerUtil.endOperation('verify_purchase');
    }
  }
  
  @override
  Future<bool> isPremiumUser() async {
    LoggerUtil.d(TAG, 'Checking premium status: $_isPremium');
    return _isPremium;
  }
  
  @override
  Future<List<SubscriptionPlan>> getAvailableSubscriptions() async {
    LoggerUtil.d(TAG, 'Getting available subscriptions');
    LoggerUtil.startOperation('get_subscriptions');
    
    final List<SubscriptionPlan> plans = [];
    
    try {
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(_productIds);
      
      LoggerUtil.d(TAG, 'Found ${response.productDetails.length} subscription products');
      
      for (final ProductDetails product in response.productDetails) {
        LoggerUtil.v(TAG, 'Processing product: ${product.id} - ${product.title}');
        
        if (product.id == AppConstants.monthlySubscriptionId) {
          plans.add(SubscriptionPlan(
            id: product.id,
            title: 'Monthly Premium',
            description: 'Unlock all premium features for one month',
            price: _extractPrice(product.price),
            period: 'month',
            features: const [
              'No ads',
              'Higher quality compression',
              'Batch processing up to 100 images',
              'Cloud storage integration',
              'Priority customer support',
            ],
          ));
          LoggerUtil.d(TAG, 'Added monthly plan: ${_extractPrice(product.price)}/${product.currencyCode} per month');
        } else if (product.id == AppConstants.yearlySubscriptionId) {
          plans.add(SubscriptionPlan(
            id: product.id,
            title: 'Yearly Premium',
            description: 'Unlock all premium features for one year (save 30%)',
            price: _extractPrice(product.price),
            period: 'year',
            features: const [
              'No ads',
              'Higher quality compression',
              'Batch processing up to 100 images',
              'Cloud storage integration',
              'Priority customer support',
              'Free future feature updates',
            ],
          ));
          LoggerUtil.d(TAG, 'Added yearly plan: ${_extractPrice(product.price)}/${product.currencyCode} per year');
        }
      }
    } catch (e) {
      LoggerUtil.e(TAG, 'Error getting subscriptions: $e');
    } finally {
      LoggerUtil.endOperation('get_subscriptions');
    }
    
    LoggerUtil.i(TAG, 'Returning ${plans.length} subscription plans');
    return plans;
  }
  
  double _extractPrice(String priceString) {
    LoggerUtil.v(TAG, 'Extracting price from string: $priceString');
    
    // This is a simple implementation and may need to be adjusted
    // depending on the format of the price string
    try {
      // Remove currency symbol and any other non-numeric characters
      final String numericString = priceString
          .replaceAll(RegExp(r'[^0-9.]'), '');
      return double.parse(numericString);
    } catch (e) {
      LoggerUtil.e(TAG, 'Error parsing price: $e');
      return 0.0;
    }
  }
  
  @override
  Future<bool> purchaseSubscription(String planId) async {
    LoggerUtil.i(TAG, 'Purchasing subscription: $planId');
    LoggerUtil.startOperation('purchase_subscription');
    
    try {
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails({planId});
      
      if (response.productDetails.isEmpty) {
        LoggerUtil.e(TAG, 'No product details found for $planId');
        LoggerUtil.endOperation('purchase_subscription');
        return false;
      }
      
      LoggerUtil.d(TAG, 'Found product details for $planId');
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
        applicationUserName: null,
      );
      
      LoggerUtil.d(TAG, 'Initiating purchase flow for $planId');
      
      bool purchaseStarted = false;
      if (Platform.isAndroid) {
        purchaseStarted = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        purchaseStarted = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }
      
      LoggerUtil.i(TAG, 'Purchase flow initiated: $purchaseStarted');
      LoggerUtil.endOperation('purchase_subscription');
      return purchaseStarted;
    } catch (e) {
      LoggerUtil.e(TAG, 'Error purchasing subscription: $e');
      LoggerUtil.endOperation('purchase_subscription');
      return false;
    }
  }
  
  @override
Future<bool> restorePurchases() async {
  LoggerUtil.i(TAG, 'Restoring purchases');
  LoggerUtil.startOperation('restore_purchases');
  
  try {
    // Add a timeout to prevent indefinite hanging
    final result = await _inAppPurchase.restorePurchases().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        LoggerUtil.w(TAG, 'Restore purchases timed out after 30 seconds');
        throw TimeoutException('Restore operation timed out');
      }
    );
    
    LoggerUtil.i(TAG, 'Restore purchases request completed');
    LoggerUtil.endOperation('restore_purchases');
    return true;
  } catch (e) {
    LoggerUtil.e(TAG, 'Error restoring purchases: $e');
    LoggerUtil.endOperation('restore_purchases');
    return false;
  }
}
  
  @override
  Stream<bool> get purchaseStatusStream => _purchaseStatusController.stream;
  
  @override
  void dispose() {
    LoggerUtil.d(TAG, 'Disposing purchase service');
    _subscription?.cancel();
    _purchaseStatusController.close();
  }
}