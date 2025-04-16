import 'package:flutter/material.dart';
import 'package:photoshrink/core/theme/app_theme.dart';
import 'package:photoshrink/data/models/subscription_plan.dart';
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/presentation/screens/subscription/widgets/subscription_card.dart';
import 'package:photoshrink/services/purchase/purchase_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final PurchaseService _purchaseService = getIt<PurchaseService>();
  List<SubscriptionPlan> _subscriptionPlans = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPlans();
  }

  Future<void> _loadSubscriptionPlans() async {
    try {
      final subscriptionPlans = await _purchaseService.getAvailableSubscriptions();
      setState(() {
        _subscriptionPlans = subscriptionPlans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load subscription plans. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribeToPlan(SubscriptionPlan plan) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _purchaseService.purchaseSubscription(plan.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription successfully activated!')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete the purchase. Please try again.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _purchaseService.restorePurchases();
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        // Check if premium after restore
        final isPremium = await _purchaseService.isPremiumUser();
        
        if (isPremium) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Premium subscription successfully restored!')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No previous subscriptions found.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore purchases. Please try again.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Subscription'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadSubscriptionPlans,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildSubscriptionContent(),
    );
  }

  Widget _buildSubscriptionContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Unlock Premium Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get the most out of PhotoShrink with a premium subscription.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Feature list
            _buildFeaturesList(),
            const SizedBox(height: 32),
            
            // Subscription cards
            if (_subscriptionPlans.isEmpty)
              const Center(
                child: Text(
                  'No subscription plans available at the moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              )
            else
              Column(
                children: _subscriptionPlans.map((plan) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SubscriptionCard(
                      plan: plan,
                      onSubscribe: () => _subscribeToPlan(plan),
                    ),
                  );
                }).toList(),
              ),
            
            // Restore purchases button
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _restorePurchases,
                child: const Text('Restore Purchases'),
              ),
            ),
            
            // Terms and privacy
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'By subscribing, you agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Subscription will be charged to your App Store or Google Play account. '
                'Subscriptions automatically renew unless auto-renew is turned off.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'title': 'No Ads',
        'description': 'Enjoy an ad-free experience throughout the app.',
        'icon': Icons.block,
      },
      {
        'title': 'Higher Quality Compression',
        'description': 'Access advanced compression algorithms for better results.',
        'icon': Icons.high_quality,
      },
      {
        'title': 'Batch Processing',
        'description': 'Compress up to 100 images at once (free version: 5 images).',
        'icon': Icons.collections,
      },
      {
        'title': 'Cloud Storage',
        'description': 'Backup your compressed images to the cloud.',
        'icon': Icons.cloud_upload,
      },
      {
        'title': 'Priority Support',
        'description': 'Get priority customer support for any issues.',
        'icon': Icons.support_agent,
      },
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['description'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}