import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {}

class UpdateDefaultCompressionQualityEvent extends SettingsEvent {
  final int quality;

  const UpdateDefaultCompressionQualityEvent(this.quality);

  @override
  List<Object?> get props => [quality];
}

class ToggleCloudStorageEvent extends SettingsEvent {
  final bool enable;

  const ToggleCloudStorageEvent(this.enable);

  @override
  List<Object?> get props => [enable];
}

class ToggleNotificationsEvent extends SettingsEvent {
  final bool enable;

  const ToggleNotificationsEvent(this.enable);

  @override
  List<Object?> get props => [enable];
}

class UpdateStorageDirectoryEvent extends SettingsEvent {
  final String directory;

  const UpdateStorageDirectoryEvent(this.directory);

  @override
  List<Object?> get props => [directory];
}

class ToggleSaveOriginalEvent extends SettingsEvent {
  final bool enable;

  const ToggleSaveOriginalEvent(this.enable);

  @override
  List<Object?> get props => [enable];
}

class ClearCompressionHistoryEvent extends SettingsEvent {}

class NavigateToSubscriptionEvent extends SettingsEvent {}