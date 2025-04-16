import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
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
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final StreamController<bool> _purchaseStatusController = StreamController<bool>.broadcast();
  bool _isPremium = false;
  
  // Product IDs to query
  final Set<String> _productIds = {
    AppConstants.monthlySubscriptionId,
    AppConstants.yearlySubscriptionId,
  };
  
  @override
  Future<void> initialize() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      _isPremium = false;
      _purchaseStatusController.add(_isPremium);
      return;
    }
    
    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        print('Error in purchase stream: $error');
      },
    );
    
    // Load products
    await _loadProducts();
    
    // Check for existing purchases
    await restorePurchases();
  }
  
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show a dialog/loading indicator
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error case
        print('Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Verify the purchase
        _verifyPurchase(purchaseDetails);
      }
      
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  Future<void> _loadProducts() async {
    final ProductDetailsResponse response = 
        await _inAppPurchase.queryProductDetails(_productIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }
  }
  
  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Here you would typically validate the receipt with your server
    // For simplicity, we're just checking if it's one of our subscription IDs
    if (_productIds.contains(purchaseDetails.productID)) {
      _isPremium = true;
      _purchaseStatusController.add(_isPremium);
    }
  }
  
  @override
  Future<bool> isPremiumUser() async {
    return _isPremium;
  }
  
  @override
  Future<List<SubscriptionPlan>> getAvailableSubscriptions() async {
    final ProductDetailsResponse response = 
        await _inAppPurchase.queryProductDetails(_productIds);
    
    final List<SubscriptionPlan> plans = [];
    
    for (final ProductDetails product in response.productDetails) {
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
      }
    }
    
    return plans;
  }
  
  double _extractPrice(String priceString) {
    // This is a simple implementation and may need to be adjusted
    // depending on the format of the price string
    try {
      // Remove currency symbol and any other non-numeric characters
      final String numericString = priceString
          .replaceAll(RegExp(r'[^0-9.]'), '');
      return double.parse(numericString);
    } catch (e) {
      print('Error parsing price: $e');
      return 0.0;
    }
  }
  
  @override
  Future<bool> purchaseSubscription(String planId) async {
    try {
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails({planId});
      
      if (response.productDetails.isEmpty) {
        print('No product details found for $planId');
        return false;
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
        applicationUserName: null,
      );
      
      if (Platform.isAndroid) {
        return _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        return _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      print('Error purchasing subscription: $e');
      return false;
    }
  }
  
  @override
  Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      print('Error restoring purchases: $e');
      return false;
    }
  }
  
  @override
  Stream<bool> get purchaseStatusStream => _purchaseStatusController.stream;
  
  @override
  void dispose() {
    _subscription?.cancel();
    _purchaseStatusController.close();
  }
}