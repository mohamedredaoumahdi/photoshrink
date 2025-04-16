import 'package:equatable/equatable.dart';
import 'package:photoshrink/data/models/user_settings.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoadSuccess extends HomeState {
  final List<String> selectedImagePaths;
  final int compressionQuality;
  final UserSettings userSettings;
  final bool isPremium;

  const HomeLoadSuccess({
    this.selectedImagePaths = const [],
    required this.compressionQuality,
    required this.userSettings,
    required this.isPremium,
  });

  HomeLoadSuccess copyWith({
    List<String>? selectedImagePaths,
    int? compressionQuality,
    UserSettings? userSettings,
    bool? isPremium,
  }) {
    return HomeLoadSuccess(
      selectedImagePaths: selectedImagePaths ?? this.selectedImagePaths,
      compressionQuality: compressionQuality ?? this.compressionQuality,
      userSettings: userSettings ?? this.userSettings,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  List<Object?> get props => [
        selectedImagePaths,
        compressionQuality,
        userSettings,
        isPremium,
      ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

class NavigateToCompressionScreen extends HomeState {
  final List<String> imagePaths;
  final int quality;

  const NavigateToCompressionScreen({
    required this.imagePaths,
    required this.quality,
  });

  @override
  List<Object?> get props => [imagePaths, quality];
}