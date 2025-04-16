import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/data/models/user_settings.dart';
import 'package:photoshrink/presentation/bloc/home/home_event.dart';
import 'package:photoshrink/presentation/bloc/home/home_state.dart';
import 'package:photoshrink/services/purchase/purchase_service.dart';
import 'package:photoshrink/services/storage/storage_service.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final StorageService _storageService;
  final PurchaseService _purchaseService;
  final ImagePicker _imagePicker = ImagePicker();

  HomeBloc({
    required StorageService storageService,
    required PurchaseService purchaseService,
  })  : _storageService = storageService,
        _purchaseService = purchaseService,
        super(HomeInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<ImageSelectionRequestedEvent>(_onImageSelectionRequested);
    on<ImagesSelectedEvent>(_onImagesSelected);
    on<CompressionQualityChangedEvent>(_onCompressionQualityChanged);
    on<StartCompressionEvent>(_onStartCompression);
    on<ClearSelectedImagesEvent>(_onClearSelectedImages);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    try {
      final UserSettings userSettings = await _storageService.getUserSettings();
      final int defaultLevel = await _storageService.getDefaultCompressionLevel();
      final bool isPremium = await _purchaseService.isPremiumUser();

      emit(HomeLoadSuccess(
        compressionQuality: defaultLevel,
        userSettings: userSettings,
        isPremium: isPremium,
      ));
    } catch (e) {
      emit(HomeError('Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> _onImageSelectionRequested(
    ImageSelectionRequestedEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoadSuccess) {
      try {
        List<XFile> selectedImages;
        
        if (event.multiple) {
          selectedImages = await _imagePicker.pickMultiImage();
        } else {
          final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
          selectedImages = image != null ? [image] : [];
        }
        
        if (selectedImages.isNotEmpty) {
          add(ImagesSelectedEvent(selectedImages.map((image) => image.path).toList()));
        }
      } catch (e) {
        emit(HomeError('Failed to pick images: ${e.toString()}'));
      }
    }
  }

  void _onImagesSelected(
    ImagesSelectedEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoadSuccess) {
      final currentState = state as HomeLoadSuccess;
      
      // For free users, limit the number of images they can select at once
      final bool isPremium = currentState.isPremium;
      final List<String> imagePaths = event.imagePaths;
      
      // Limit non-premium users to 5 images at a time
      final List<String> limitedPaths = isPremium 
          ? imagePaths 
          : imagePaths.take(5).toList();
      
      emit(currentState.copyWith(
        selectedImagePaths: [...currentState.selectedImagePaths, ...limitedPaths],
      ));
    }
  }

  void _onCompressionQualityChanged(
    CompressionQualityChangedEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoadSuccess) {
      final currentState = state as HomeLoadSuccess;
      emit(currentState.copyWith(compressionQuality: event.quality));
    }
  }

  void _onStartCompression(
    StartCompressionEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoadSuccess) {
      final currentState = state as HomeLoadSuccess;
      
      if (currentState.selectedImagePaths.isEmpty) {
        emit(const HomeError(AppConstants.noImagesSelectedMessage));
        emit(currentState); // Revert back to the previous state
        return;
      }
      
      emit(NavigateToCompressionScreen(
        imagePaths: currentState.selectedImagePaths,
        quality: currentState.compressionQuality,
      ));
      
      // After navigation, we clear the selected images
      add(ClearSelectedImagesEvent());
    }
  }

  void _onClearSelectedImages(
    ClearSelectedImagesEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoadSuccess) {
      final currentState = state as HomeLoadSuccess;
      emit(currentState.copyWith(selectedImagePaths: []));
    }
  }

}