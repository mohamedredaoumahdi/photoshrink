import 'package:equatable/equatable.dart';
import 'package:photoshrink/data/models/user_settings.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final UserSettings settings;
  final bool isPremiumUser;

  const SettingsLoaded({
    required this.settings,
    required this.isPremiumUser,
  });

  @override
  List<Object?> get props => [settings, isPremiumUser];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class NavigateToSubscription extends SettingsState {}