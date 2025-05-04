import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:photoshrink/data/models/user_settings.dart';
import 'package:photoshrink/presentation/bloc/settings/settings_event.dart';
import 'package:photoshrink/presentation/bloc/settings/settings_state.dart';
import 'package:photoshrink/services/purchase/purchase_service.dart';
import 'package:photoshrink/services/storage/storage_service.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const String TAG = 'SettingsBloc';
  
  final StorageService _storageService;
  final PurchaseService _purchaseService;

  SettingsBloc({
    required StorageService storageService,
    required PurchaseService purchaseService,
  })  : _storageService = storageService,
        _purchaseService = purchaseService,
        super(SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateDefaultCompressionQualityEvent>(_onUpdateDefaultCompressionQuality);
    on<ToggleCloudStorageEvent>(_onToggleCloudStorage);
    on<ToggleNotificationsEvent>(_onToggleNotifications);
    on<UpdateStorageDirectoryEvent>(_onUpdateStorageDirectory);
    on<ToggleSaveOriginalEvent>(_onToggleSaveOriginal);
    on<ClearCompressionHistoryEvent>(_onClearCompressionHistory);
    on<NavigateToSubscriptionEvent>(_onNavigateToSubscription);
    
    LoggerUtil.i(TAG, 'SettingsBloc initialized');
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    LoggerUtil.d(TAG, 'Loading settings');
    emit(SettingsLoading());
    
    try {
      final UserSettings settings = await _storageService.getUserSettings();
      final bool isPremium = await _purchaseService.isPremiumUser();
      
      LoggerUtil.d(TAG, 'Settings loaded - isPremium: $isPremium, cloudStorage: ${settings.enableCloudStorage}, notifications: ${settings.enableNotifications}');
      
      emit(SettingsLoaded(settings: settings, isPremiumUser: isPremium));
    } catch (e) {
      LoggerUtil.e(TAG, 'Failed to load settings: $e');
      emit(SettingsError('Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateDefaultCompressionQuality(
    UpdateDefaultCompressionQualityEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      try {
        final currentState = state as SettingsLoaded;
        LoggerUtil.d(TAG, 'Updating default compression quality from ${currentState.settings.defaultCompressionQuality} to ${event.quality}');
        
        final updatedSettings = currentState.settings.copyWith(
          defaultCompressionQuality: event.quality,
        );
        
        await _storageService.saveUserSettings(updatedSettings);
        await _storageService.setDefaultCompressionLevel(event.quality);
        
        LoggerUtil.i(TAG, 'Default compression quality updated to ${event.quality}');
        
        emit(SettingsLoaded(
          settings: updatedSettings,
          isPremiumUser: currentState.isPremiumUser,
        ));
      } catch (e) {
        LoggerUtil.e(TAG, 'Failed to update compression quality: $e');
        emit(SettingsError('Failed to update compression quality: ${e.toString()}'));
        // Revert back to the previous state
        emit(state);
      }
    } else {
      LoggerUtil.w(TAG, 'Update compression quality requested but state is not SettingsLoaded');
    }
  }

  Future<void> _onToggleCloudStorage(
    ToggleCloudStorageEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      try {
        final currentState = state as SettingsLoaded;
        LoggerUtil.d(TAG, 'Toggling cloud storage from ${currentState.settings.enableCloudStorage} to ${event.enable}');
        
        final updatedSettings = currentState.settings.copyWith(
          enableCloudStorage: event.enable,
        );
        
        await _storageService.saveUserSettings(updatedSettings);
        
        LoggerUtil.i(TAG, 'Cloud storage setting updated to ${event.enable}');
        
        emit(SettingsLoaded(
          settings: updatedSettings,
          isPremiumUser: currentState.isPremiumUser,
        ));
      } catch (e) {
        LoggerUtil.e(TAG, 'Failed to toggle cloud storage: $e');
        emit(SettingsError('Failed to toggle cloud storage: ${e.toString()}'));
        emit(state);
      }
    } else {
      LoggerUtil.w(TAG, 'Toggle cloud storage requested but state is not SettingsLoaded');
    }
  }

  Future<void> _onToggleNotifications(
    ToggleNotificationsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      try {
        final currentState = state as SettingsLoaded;
        LoggerUtil.d(TAG, 'Toggling notifications from ${currentState.settings.enableNotifications} to ${event.enable}');
        
        final updatedSettings = currentState.settings.copyWith(
          enableNotifications: event.enable,
        );
        
        await _storageService.saveUserSettings(updatedSettings);
        
        LoggerUtil.i(TAG, 'Notifications setting updated to ${event.enable}');
        
        emit(SettingsLoaded(
          settings: updatedSettings,
          isPremiumUser: currentState.isPremiumUser,
        ));
      } catch (e) {
        LoggerUtil.e(TAG, 'Failed to toggle notifications: $e');
        emit(SettingsError('Failed to toggle notifications: ${e.toString()}'));
        emit(state);
      }
    } else {
      LoggerUtil.w(TAG, 'Toggle notifications requested but state is not SettingsLoaded');
    }
  }

  Future<void> _onUpdateStorageDirectory(
    UpdateStorageDirectoryEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      try {
        final currentState = state as SettingsLoaded;
        LoggerUtil.d(TAG, 'Updating storage directory to ${LoggerUtil.truncatePath(event.directory)}');
        
        final updatedSettings = currentState.settings.copyWith(
          preferredStorageDirectory: event.directory,
        );
        
        await _storageService.saveUserSettings(updatedSettings);
        
        LoggerUtil.i(TAG, 'Storage directory updated');
        
        emit(SettingsLoaded(
          settings: updatedSettings,
          isPremiumUser: currentState.isPremiumUser,
        ));
      } catch (e) {
        LoggerUtil.e(TAG, 'Failed to update storage directory: $e');
        emit(SettingsError('Failed to update storage directory: ${e.toString()}'));
        emit(state);
      }
    } else {
      LoggerUtil.w(TAG, 'Update storage directory requested but state is not SettingsLoaded');
    }
  }

  Future<void> _onToggleSaveOriginal(
    ToggleSaveOriginalEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      try {
        final currentState = state as SettingsLoaded;
        LoggerUtil.d(TAG, 'Toggling save original setting from ${currentState.settings.saveOriginalAfterCompression} to ${event.enable}');
        
        final updatedSettings = currentState.settings.copyWith(
          saveOriginalAfterCompression: event.enable,
        );
        
        await _storageService.saveUserSettings(updatedSettings);
        
        LoggerUtil.i(TAG, 'Save original setting updated to ${event.enable}');
        
        emit(SettingsLoaded(
          settings: updatedSettings,
          isPremiumUser: currentState.isPremiumUser,
        ));
      } catch (e) {
        LoggerUtil.e(TAG, 'Failed to toggle save original: $e');
        emit(SettingsError('Failed to toggle save original: ${e.toString()}'));
        emit(state);
      }
    } else {
      LoggerUtil.w(TAG, 'Toggle save original requested but state is not SettingsLoaded');
    }
  }

  Future<void> _onClearCompressionHistory(
    ClearCompressionHistoryEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      try {
        LoggerUtil.d(TAG, 'Clearing compression history');
        await _storageService.clearCompressionHistory();
        LoggerUtil.i(TAG, 'Compression history cleared successfully');
        
        emit(SettingsLoaded(
          settings: (state as SettingsLoaded).settings,
          isPremiumUser: (state as SettingsLoaded).isPremiumUser,
        ));
      } catch (e) {
        LoggerUtil.e(TAG, 'Failed to clear compression history: $e');
        emit(SettingsError('Failed to clear compression history: ${e.toString()}'));
        emit(state);
      }
    } else {
      LoggerUtil.w(TAG, 'Clear compression history requested but state is not SettingsLoaded');
    }
  }

  void _onNavigateToSubscription(
    NavigateToSubscriptionEvent event,
    Emitter<SettingsState> emit,
  ) {
    LoggerUtil.i(TAG, 'Navigating to subscription screen');
    emit(NavigateToSubscription());
    
    // After navigation, we want to revert back to the settings state
    if (state is SettingsLoaded) {
      emit(state);
    } else {
      add(LoadSettingsEvent());
    }
  }
}