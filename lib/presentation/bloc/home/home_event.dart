import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends HomeEvent {}

class ImageSelectionRequestedEvent extends HomeEvent {
  final bool multiple;

  const ImageSelectionRequestedEvent({this.multiple = true});

  @override
  List<Object?> get props => [multiple];
}

class ImagesSelectedEvent extends HomeEvent {
  final List<String> imagePaths;

  const ImagesSelectedEvent(this.imagePaths);

  @override
  List<Object?> get props => [imagePaths];
}

class CompressionQualityChangedEvent extends HomeEvent {
  final int quality;

  const CompressionQualityChangedEvent(this.quality);

  @override
  List<Object?> get props => [quality];
}

class StartCompressionEvent extends HomeEvent {}

class ClearSelectedImagesEvent extends HomeEvent {}