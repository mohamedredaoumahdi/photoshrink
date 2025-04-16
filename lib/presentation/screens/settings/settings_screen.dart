import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/constants/route_constants.dart';
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/presentation/bloc/settings/settings_bloc.dart';
import 'package:photoshrink/presentation/bloc/settings/settings_event.dart';
import 'package:photoshrink/presentation/bloc/settings/settings_state.dart';
import 'package:photoshrink/presentation/common_widgets/loading_indicator.dart';
import 'package:photoshrink/presentation/screens/settings/widgets/settings_section.dart';
import 'package:photoshrink/presentation/screens/settings/widgets/settings_switch_tile.dart';
import 'package:photoshrink/presentation/screens/settings/widgets/settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsBloc _settingsBloc = getIt<SettingsBloc>();

  @override
  void initState() {
    super.initState();
    _settingsBloc.add(LoadSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _settingsBloc,
      child: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is NavigateToSubscription) {
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
                    // Navigate to profile screen
                  },
                ),
                SettingsTile(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  onTap: () {
                    // Handle sign out
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
                    context.read<SettingsBloc>().add(NavigateToSubscriptionEvent());
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
                  onTap: () {
                    // Handle restore purchases
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
                  _showQualityDialog(context, state.settings.defaultCompressionQuality);
                },
              ),
              SettingsSwitchTile(
                icon: Icons.save,
                title: 'Save Original',
                subtitle: 'Keep original images after compression',
                value: state.settings.saveOriginalAfterCompression,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(ToggleSaveOriginalEvent(value));
                },
              ),
              SettingsTile(
                icon: Icons.folder,
                title: 'Storage Location',
                subtitle: state.settings.preferredStorageDirectory.isEmpty
                    ? 'Default location'
                    : state.settings.preferredStorageDirectory,
                onTap: () {
                  // Show directory picker
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
                        context.read<SettingsBloc>().add(ToggleCloudStorageEvent(value));
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
                  context.read<SettingsBloc>().add(ToggleNotificationsEvent(value));
                },
              ),
              SettingsTile(
                icon: Icons.history,
                title: 'Compression History',
                subtitle: 'Clear your compression history',
                onTap: () {
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
                  // Show app info dialog
                },
              ),
              SettingsTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                onTap: () {
                  // Open privacy policy
                },
              ),
              SettingsTile(
                icon: Icons.description,
                title: 'Terms of Service',
                onTap: () {
                  // Open terms of service
                },
              ),
              SettingsTile(
                icon: Icons.help,
                title: 'Help & Support',
                onTap: () {
                  // Open help & support
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
      builder: (context) => AlertDialog(
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
                  Navigator.of(context).pop();
                  context.read<SettingsBloc>().add(
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
                  Navigator.of(context).pop();
                  context.read<SettingsBloc>().add(
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
                  Navigator.of(context).pop();
                  context.read<SettingsBloc>().add(
                        UpdateDefaultCompressionQualityEvent(value!),
                      );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Compression History'),
        content: const Text(
          'Are you sure you want to clear your compression history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SettingsBloc>().add(ClearCompressionHistoryEvent());
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
}