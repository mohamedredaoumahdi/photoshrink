import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/constants/route_constants.dart';
import 'package:photoshrink/core/utils/directory_picker.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/presentation/bloc/settings/settings_bloc.dart';
import 'package:photoshrink/presentation/bloc/settings/settings_event.dart';
import 'package:photoshrink/presentation/bloc/settings/settings_state.dart';
import 'package:photoshrink/presentation/common_widgets/loading_indicator.dart';
import 'package:photoshrink/presentation/screens/settings/widgets/settings_section.dart';
import 'package:photoshrink/presentation/screens/settings/widgets/settings_switch_tile.dart';
import 'package:photoshrink/presentation/screens/settings/widgets/settings_tile.dart';
import 'package:photoshrink/services/auth/auth_service.dart';
import 'package:photoshrink/services/purchase/purchase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String TAG = 'SettingsScreen';
  final SettingsBloc _settingsBloc = getIt<SettingsBloc>();
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    LoggerUtil.d(TAG, 'Initializing settings screen');
    _settingsBloc.add(LoadSettingsEvent());
  }
  
  @override
  void dispose() {
    LoggerUtil.d(TAG, 'Disposing settings screen');
    _mounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _settingsBloc,
      child: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (!_mounted) return;
          
          if (state is SettingsError) {
            LoggerUtil.e(TAG, 'Settings error: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is NavigateToSubscription) {
            LoggerUtil.i(TAG, 'Navigating to subscription screen');
            Navigator.of(context).pushNamed(RouteConstants.subscription);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Settings'),
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, SettingsState state) {
    if (state is SettingsInitial || state is SettingsLoading) {
      return const LoadingIndicator();
    } else if (state is SettingsLoaded) {
      LoggerUtil.d(TAG, 'Building settings UI with loaded state');
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Account section (if auth is enabled)
          if (AppConstants.enableUserAuthentication) ...[
            SettingsSection(
              title: 'Account',
              children: [
                SettingsTile(
                  icon: Icons.person,
                  title: 'Profile',
                  subtitle: 'View and edit your profile',
                  onTap: () {
                    LoggerUtil.d(TAG, 'Profile tile tapped');
                    _showProfileDialog(context, state.isPremiumUser);
                  },
                ),
                SettingsTile(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  onTap: () {
                    LoggerUtil.d(TAG, 'Sign out tile tapped');
                    _showSignOutConfirmationDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Subscription section
          SettingsSection(
            title: 'Subscription',
            children: [
              SettingsTile(
                icon: Icons.star,
                title: state.isPremiumUser ? 'Premium User' : 'Upgrade to Premium',
                subtitle: state.isPremiumUser
                    ? 'Enjoy all premium features'
                    : 'Remove ads, unlock more features',
                onTap: () {
                  if (!state.isPremiumUser) {
                    LoggerUtil.d(TAG, 'Upgrade to premium tile tapped');
                    // Important: Use the BlocProvider.of to access the bloc
                    BlocProvider.of<SettingsBloc>(context).add(NavigateToSubscriptionEvent());
                  }
                },
                trailing: state.isPremiumUser
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.chevron_right),
              ),
              if (!state.isPremiumUser)
                SettingsTile(
                  icon: Icons.restore,
                  title: 'Restore Purchases',
                  onTap: () async {
                    LoggerUtil.d(TAG, 'Restore purchases tile tapped');
                    _restorePurchases(context);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Compression settings section
          SettingsSection(
            title: 'Compression Settings',
            children: [
              SettingsTile(
                icon: Icons.photo_size_select_large,
                title: 'Default Quality',
                subtitle: _getQualityLabel(state.settings.defaultCompressionQuality),
                onTap: () {
                  LoggerUtil.d(TAG, 'Default quality tile tapped');
                  _showQualityDialog(context, state.settings.defaultCompressionQuality);
                },
              ),
              SettingsSwitchTile(
                icon: Icons.save,
                title: 'Save Original',
                subtitle: 'Keep original images after compression',
                value: state.settings.saveOriginalAfterCompression,
                onChanged: (value) {
                  LoggerUtil.d(TAG, 'Save original toggled: $value');
                  BlocProvider.of<SettingsBloc>(context).add(ToggleSaveOriginalEvent(value));
                },
              ),
              SettingsTile(
                icon: Icons.folder,
                title: 'Storage Location',
                subtitle: state.settings.preferredStorageDirectory.isEmpty
                    ? 'Default location'
                    : state.settings.preferredStorageDirectory,
                onTap: () async {
                  LoggerUtil.d(TAG, 'Storage location tile tapped');
                  // Show directory picker
                  final selectedDir = await DirectoryPicker.showDirectoryPicker(context);
                  if (selectedDir != null) {
                    LoggerUtil.i(TAG, 'New storage location selected: $selectedDir');
                    BlocProvider.of<SettingsBloc>(context).add(
                      UpdateStorageDirectoryEvent(selectedDir),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // App settings section
          SettingsSection(
            title: 'App Settings',
            children: [
              SettingsSwitchTile(
                icon: Icons.cloud_upload,
                title: 'Cloud Storage',
                subtitle: 'Enable cloud backup for compressed images',
                value: state.settings.enableCloudStorage,
                onChanged: state.isPremiumUser
                    ? (value) {
                        LoggerUtil.d(TAG, 'Cloud storage toggled: $value');
                        BlocProvider.of<SettingsBloc>(context).add(ToggleCloudStorageEvent(value));
                      }
                    : null,
                premium: !state.isPremiumUser,
              ),
              SettingsSwitchTile(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Receive notifications about app updates',
                value: state.settings.enableNotifications,
                onChanged: (value) {
                  LoggerUtil.d(TAG, 'Notifications toggled: $value');
                  BlocProvider.of<SettingsBloc>(context).add(ToggleNotificationsEvent(value));
                },
              ),
              SettingsTile(
                icon: Icons.history,
                title: 'Compression History',
                subtitle: 'Clear your compression history',
                onTap: () {
                  LoggerUtil.d(TAG, 'Compression history tile tapped');
                  _showClearHistoryDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // About section
          SettingsSection(
            title: 'About',
            children: [
              SettingsTile(
                icon: Icons.info,
                title: 'App Info',
                subtitle: 'Version ${AppConstants.appVersion}',
                onTap: () {
                  LoggerUtil.d(TAG, 'App info tile tapped');
                  _showAppInfoDialog(context);
                },
              ),
              SettingsTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                onTap: () {
                  LoggerUtil.d(TAG, 'Privacy policy tile tapped');
                  _openPrivacyPolicy(context);
                },
              ),
              SettingsTile(
                icon: Icons.description,
                title: 'Terms of Service',
                onTap: () {
                  LoggerUtil.d(TAG, 'Terms of service tile tapped');
                  _openTermsOfService(context);
                },
              ),
              SettingsTile(
                icon: Icons.help,
                title: 'Help & Support',
                onTap: () {
                  LoggerUtil.d(TAG, 'Help & support tile tapped');
                  _openHelpAndSupport(context);
                },
              ),
            ],
          ),
        ],
      );
    } else {
      return const Center(
        child: Text('Something went wrong. Please try again.'),
      );
    }
  }

  void _showQualityDialog(BuildContext context, int currentQuality) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Default Compression Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Low Quality'),
              subtitle: const Text('Maximum compression, smaller files'),
              leading: Radio<int>(
                value: AppConstants.lowQuality,
                groupValue: currentQuality,
                onChanged: (value) {
                  Navigator.of(dialogContext).pop();
                  // Access the bloc from the original context, not the dialog context
                  BlocProvider.of<SettingsBloc>(context).add(
                    UpdateDefaultCompressionQualityEvent(value!),
                  );
                },
              ),
            ),
            ListTile(
              title: const Text('Medium Quality'),
              subtitle: const Text('Balanced compression and quality'),
              leading: Radio<int>(
                value: AppConstants.mediumQuality,
                groupValue: currentQuality,
                onChanged: (value) {
                  Navigator.of(dialogContext).pop();
                  // Access the bloc from the original context, not the dialog context
                  BlocProvider.of<SettingsBloc>(context).add(
                    UpdateDefaultCompressionQualityEvent(value!),
                  );
                },
              ),
            ),
            ListTile(
              title: const Text('High Quality'),
              subtitle: const Text('Better quality, larger files'),
              leading: Radio<int>(
                value: AppConstants.highQuality,
                groupValue: currentQuality,
                onChanged: (value) {
                  Navigator.of(dialogContext).pop();
                  // Access the bloc from the original context, not the dialog context
                  BlocProvider.of<SettingsBloc>(context).add(
                    UpdateDefaultCompressionQualityEvent(value!),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Compression History'),
        content: const Text(
          'Are you sure you want to clear your compression history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Access the bloc from the original context, not the dialog context
              BlocProvider.of<SettingsBloc>(context).add(ClearCompressionHistoryEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compression history cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _getQualityLabel(int quality) {
    if (quality <= AppConstants.lowQuality) {
      return 'Low (Maximum Compression)';
    } else if (quality <= AppConstants.mediumQuality) {
      return 'Medium (Balanced)';
    } else {
      return 'High (Better Quality)';
    }
  }
  
  // Show user profile dialog - FIXED to pass isPremiumUser from the parent
  void _showProfileDialog(BuildContext context, bool isPremiumUser) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('User Profile'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Get current user from AuthBloc if authenticated
                FutureBuilder(
                  future: getIt<AuthService>().currentUser != null 
                    ? Future.value(getIt<AuthService>().currentUser)
                    : Future.value(null),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final user = snapshot.data;
                    if (user == null) {
                      return const Text('Not signed in');
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileField('Email', user.email ?? 'No email'),
                        _buildProfileField('User ID', user.uid),
                        _buildProfileField('Created', _formatDate(user.metadata.creationTime)),
                        _buildProfileField('Last Sign In', _formatDate(user.metadata.lastSignInTime)),
                        _buildProfileField('Email Verified', user.emailVerified ? 'Yes' : 'No'),
                        _buildProfileField('Premium', isPremiumUser ? 'Yes' : 'No'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Implement edit profile functionality in the future
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit profile feature coming soon!')),
                );
              }
            },
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }
  
  // Helper to build a profile field
  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  // Format a date for display
  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
  
  // Show sign out confirmation dialog
  void _showSignOutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _signOut(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
  
  // Handle sign out
  Future<void> _signOut(BuildContext context) async {
    try {
      LoggerUtil.i(TAG, 'Signing out user');
      await getIt<AuthService>().signOut();
      
      // Navigate to auth screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteConstants.auth, 
          (route) => false
        );
      }
    } catch (e) {
      LoggerUtil.e(TAG, 'Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }
  
  // Handle restore purchases
  // Update the _restorePurchases method in your SettingsScreen class
Future<void> _restorePurchases(BuildContext context) async {
  // Show loading dialog
  final dialogContext = await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => WillPopScope(
      // Prevent back button from dismissing the dialog
      onWillPop: () async => false,
      child: const AlertDialog(
        title: Text('Restoring Purchases'),
        content: SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    ),
  );
  
  // Add a safety timeout to ensure the dialog is closed
  Timer? timeoutTimer;
  timeoutTimer = Timer(const Duration(seconds: 60), () {
    LoggerUtil.w(TAG, 'Restore purchases safety timeout triggered');
    // Ensure dialog is dismissed if still showing
    if (mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (e) {
        LoggerUtil.e(TAG, 'Error dismissing dialog: $e');
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore operation timed out. Please try again.')),
      );
    }
  });
  
  try {
    LoggerUtil.i(TAG, 'Restoring purchases');
    final purchaseService = getIt<PurchaseService>();
    final success = await purchaseService.restorePurchases();
    
    // Cancel the safety timer since we got a response
    timeoutTimer.cancel();
    
    // Make sure dialog is dismissed
    if (mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (e) {
        LoggerUtil.e(TAG, 'Error dismissing dialog after restore: $e');
        // Continue with processing even if dialog dismiss fails
      }
      
      if (success) {
        // Check if premium after restore
        final isPremium = await purchaseService.isPremiumUser();
        
        if (isPremium) {
          LoggerUtil.i(TAG, 'Premium subscription successfully restored');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Premium subscription successfully restored!')),
          );
          
          // Refresh settings to reflect new premium status
          BlocProvider.of<SettingsBloc>(context).add(LoadSettingsEvent());
        } else {
          LoggerUtil.i(TAG, 'No previous subscriptions found');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No previous subscriptions found.')),
          );
        }
      } else {
        LoggerUtil.w(TAG, 'Failed to restore purchases');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore purchases. Please try again.')),
        );
      }
    }
  } catch (e) {
    // Cancel the safety timer
    timeoutTimer.cancel();
    
    // Ensure dialog is dismissed even when error occurs
    if (mounted) {
      try {
        // Use rootNavigator to make sure we're closing the dialog
        Navigator.of(context, rootNavigator: true).pop();
      } catch (dialogError) {
        LoggerUtil.e(TAG, 'Error dismissing dialog on error: $dialogError');
        // Continue with error handling even if dialog dismiss fails
      }
      
      LoggerUtil.e(TAG, 'Error restoring purchases: $e');
      
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().split('Exception:').last}')),
      );
    }
  }
}
  
  // Show app info dialog
  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('App Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoField('App Name', AppConstants.appName),
            _buildInfoField('Version', AppConstants.appVersion),
            _buildInfoField('Platform', Theme.of(context).platform.toString().split('.').last),
            _buildInfoField('Developer', 'PhotoShrink Team'),
            _buildInfoField('Released', '2025'),
            const SizedBox(height: 16),
            const Text(
              'PhotoShrink is an image compression and archiving app that helps you save storage space without sacrificing image quality.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Helper to build info field
  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  // Open privacy policy
  void _openPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This is a placeholder for the Privacy Policy content. In a real app, this would contain the actual privacy policy text or link to an external website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Open terms of service
  void _openTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'This is a placeholder for the Terms of Service content. In a real app, this would contain the actual terms of service text or link to an external website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Open help & support
  void _openHelpAndSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need help with PhotoShrink? Here are some options:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSupportOption(
              icon: Icons.email,
              title: 'Email Support',
              description: 'support@photoshrink.com',
            ),
            const SizedBox(height: 8),
            _buildSupportOption(
              icon: Icons.question_answer,
              title: 'FAQ',
              description: 'Frequently asked questions and answers',
            ),
            const SizedBox(height: 8),
            _buildSupportOption(
              icon: Icons.web,
              title: 'Website',
              description: 'www.photoshrink.com',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Build support option
  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}