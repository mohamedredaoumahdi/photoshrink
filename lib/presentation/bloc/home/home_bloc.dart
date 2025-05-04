import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:photoshrink/data/models/user_settings.dart';
import 'package:photoshrink/presentation/bloc/home/home_event.dart';
import 'package:photoshrink/presentation/bloc/home/home_state.dart';
import 'package:photoshrink/services/purchase/purchase_service.dart';
import 'package:photoshrink/services/storage/storage_service.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  static const String TAG = 'HomeBloc';
  
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
    
    LoggerUtil.i(TAG, 'HomeBloc initialized');
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<HomeState> emit,
  ) async {
    LoggerUtil.d(TAG, 'Loading user settings and preferences');
    emit(HomeLoading());
    
    try {
      final UserSettings userSettings = await _storageService.getUserSettings();
      final int defaultLevel = await _storageService.getDefaultCompressionLevel();
      final bool isPremium = await _purchaseService.isPremiumUser();

      LoggerUtil.d(TAG, 'Settings loaded - Default compression: $defaultLevel, Premium: $isPremium');
      
      emit(HomeLoadSuccess(
        compressionQuality: defaultLevel,
        userSettings: userSettings,
        isPremium: isPremium,
      ));
    } catch (e) {
      LoggerUtil.e(TAG, 'Failed to load settings: $e');
      emit(HomeError('Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> _onImageSelectionRequested(
    ImageSelectionRequestedEvent event,
    Emitter<HomeState> emit,
  ) async {
    LoggerUtil.d(TAG, 'Image selection requested (multiple: ${event.multiple})');
    
    if (state is HomeLoadSuccess) {
      try {
        List<XFile> selectedImages;
        
        if (event.multiple) {
          LoggerUtil.d(TAG, 'Opening gallery for multiple image selection');
          selectedImages = await _imagePicker.pickMultiImage();
        } else {
          LoggerUtil.d(TAG, 'Opening gallery for single image selection');
          final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
          selectedImages = image != null ? [image] : [];
        }
        
        LoggerUtil.i(TAG, 'User selected ${selectedImages.length} images');
        
        if (selectedImages.isNotEmpty) {
          add(ImagesSelectedEvent(selectedImages.map((image) => image.path).toList()));
        } else {
          LoggerUtil.d(TAG, 'No images were selected');
        }
      } catch (e) {
        LoggerUtil.e(TAG, 'Error picking images: $e');
        emit(HomeError('Failed to pick images: ${e.toString()}'));
      }
    } else {
      LoggerUtil.w(TAG, 'Image selection requested but state is not HomeLoadSuccess');
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
      
      LoggerUtil.d(TAG, 'Processing ${imagePaths.length} selected images (premium: $isPremium)');
      
      // Limit non-premium users to 5 images at a time
      final List<String> limitedPaths = isPremium 
          ? imagePaths 
          : imagePaths.take(5).toList();
      
      if (!isPremium && imagePaths.length > 5) {
        LoggerUtil.i(TAG, 'Non-premium user tried to select ${imagePaths.length} images, limiting to 5');
      }
      
      emit(currentState.copyWith(
        selectedImagePaths: [...currentState.selectedImagePaths, ...limitedPaths],
      ));
      
      LoggerUtil.i(TAG, 'Updated image selection: ${currentState.selectedImagePaths.length + limitedPaths.length} total images');
    } else {
      LoggerUtil.w(TAG, 'Images selected but state is not HomeLoadSuccess');
    }
  }

  void _onCompressionQualityChanged(
    CompressionQualityChangedEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoadSuccess) {
      final currentState = state as HomeLoadSuccess;
      LoggerUtil.d(TAG, 'Changing compression quality from ${currentState.compressionQuality} to ${event.quality}');
      emit(currentState.copyWith(compressionQuality: event.quality));
    } else {
      LoggerUtil.w(TAG, 'Compression quality change requested but state is not HomeLoadSuccess');
    }
  }

  void _onStartCompression(
    StartCompressionEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoadSuccess) {
      final currentState = state as HomeLoadSuccess;
      
      if (currentState.selectedImagePaths.isEmpty) {
        LoggerUtil.w(TAG, 'Compression started with no images selected');
        emit(const HomeError(AppConstants.noImagesSelectedMessage));
        emit(currentState); // Revert back to the previous state
        return;
      }
      
      LoggerUtil.i(TAG, 'Starting compression process for ${currentState.selectedImagePaths.length} images with quality ${currentState.compressionQuality}');
      
      emit(NavigateToCompressionScreen(
        imagePaths: currentState.selectedImagePaths,
        quality: currentState.compressionQuality,
      ));
      
      // After navigation, we clear the selected images
      add(ClearSelectedImagesEvent());
    } else {
      LoggerUtil.w(TAG, 'Compression started but state is not HomeLoadSuccess');
    }
  }

  void _onClearSelectedImages(
    ClearSelectedImagesEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoadSuccess) {
      final currentState = state as HomeLoadSuccess;
      LoggerUtil.d(TAG, 'Clearing ${currentState.selectedImagePaths.length} selected images');
      emit(currentState.copyWith(selectedImagePaths: []));
    } else {
      LoggerUtil.w(TAG, 'Clear selected images requested but state is not HomeLoadSuccess');
    }
  }
}