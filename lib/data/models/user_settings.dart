import 'package:equatable/equatable.dart';
import 'package:photoshrink/core/constants/app_constants.dart';

class UserSettings extends Equatable {
  final int defaultCompressionQuality;
  final bool enableCloudStorage;
  final bool enableNotifications;
  final String preferredStorageDirectory;
  final bool saveOriginalAfterCompression;

  const UserSettings({
    required this.defaultCompressionQuality,
    required this.enableCloudStorage,
    required this.enableNotifications,
    required this.preferredStorageDirectory,
    required this.saveOriginalAfterCompression,
  });

  factory UserSettings.defaultSettings() {
    return UserSettings(
      defaultCompressionQuality: AppConstants.mediumQuality,
      enableCloudStorage: false,
      enableNotifications: true,
      preferredStorageDirectory: '',
      saveOriginalAfterCompression: true,
    );
  }

  UserSettings copyWith({
    int? defaultCompressionQuality,
    bool? enableCloudStorage,
    bool? enableNotifications,
    String? preferredStorageDirectory,
    bool? saveOriginalAfterCompression,
  }) {
    return UserSettings(
      defaultCompressionQuality: defaultCompressionQuality ?? this.defaultCompressionQuality,
      enableCloudStorage: enableCloudStorage ?? this.enableCloudStorage,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      preferredStorageDirectory: preferredStorageDirectory ?? this.preferredStorageDirectory,
      saveOriginalAfterCompression: saveOriginalAfterCompression ?? this.saveOriginalAfterCompression,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      defaultCompressionQuality: json['defaultCompressionQuality'] as int? ?? AppConstants.mediumQuality,
      enableCloudStorage: json['enableCloudStorage'] as bool? ?? false,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      preferredStorageDirectory: json['preferredStorageDirectory'] as String? ?? '',
      saveOriginalAfterCompression: json['saveOriginalAfterCompression'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultCompressionQuality': defaultCompressionQuality,
      'enableCloudStorage': enableCloudStorage,
      'enableNotifications': enableNotifications,
      'preferredStorageDirectory': preferredStorageDirectory,
      'saveOriginalAfterCompression': saveOriginalAfterCompression,
    };
  }

  @override
  List<Object?> get props => [
    defaultCompressionQuality,
    enableCloudStorage,
    enableNotifications,
    preferredStorageDirectory,
    saveOriginalAfterCompression,
  ];
}