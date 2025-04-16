import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photoshrink/data/models/user_settings.dart';
import 'package:photoshrink/presentation/bloc/settings/settings_event.dart';
import 'package:photoshrink/presentation/bloc/settings/settings_state.dart';
import 'package:photoshrink/services/purchase/purchase_service.dart';
import 'package:photoshrink/services/storage/storage_service.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
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
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final UserSettings settings = await _storageService.getUserSettings();
      final bool isPremium = await _purchaseService.isPremiumUser();
      emit(SettingsLoaded(settings: settings, isPremiumUser: isPremium));
    } catch (e) {
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
        final updatedSettings = currentState.settings.copyWith(
          defaultCompressionQuality: event.quality,
        );
        
        await _storageService.saveUserSettings(updatedSettings);
        await _storageService.setDefaultCompressionLevel(event.quality);
        
        emit(SettingsLoaded(
          settings: updatedSettings,
          isPremiumUser: currentState.isPremiumUser,
        ));
      } catch (e) {
        emit(SettingsError('Failed to update compression quality: ${e.toString()}'));
        // Revert back to the previous state
        emit(state);
      }
    }
  }

  Future<void> _onToggleCloudStorage(
    ToggleCloudStorageEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      try {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          enableCloudStorage: event.enable,
        );
        
        await _storageService.saveUserSettings(updatedSettings);
        
        emit(SettingsLoaded(
          settings: updatedSettings,
          isPremiumUser: currentState.isPremiumUser,
        ));
      } catch (e) {
        emit(SettingsError('Failed to toggle cloud storage: ${e.toString()}'));
        emit(state);
      }
    }
  }

  Future<void> _onToggleNotifications(
    ToggleNotificationsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      try {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          enableNotifications: event.enable,
        );
        
        await _storageService.saveUserSettings(updatedSettings);
        
        emit(SettingsLoaded(
          settings: updatedSettings,
          isPremiumUser: currentState.isPremiumUser,
        ));
      } catch (e) {
        emit(SettingsError('Failed to toggle notifications: ${e.toString()}'));
        emit(state);
      }
    }
  }

  Future<void> _onUpdateStorageDirectory(
    UpdateStorageDirectoryEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      try {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          preferredStorageDirectory: event.directory,
        );
        
        await _storageService.saveUserSettings(updatedSettings);
        
        emit(SettingsLoaded(
          settings: updatedSettings,
          isPremiumUser: currentState.isPremiumUser,
        ));
      } catch (e) {
        emit(SettingsError('Failed to update storage directory: ${e.toString()}'));
        emit(state);
      }
    }
  }

  Future<void> _onToggleSaveOriginal(
    ToggleSaveOriginalEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      try {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          saveOriginalAfterCompression: event.enable,
        );
        
        await _storageService.saveUserSettings(updatedSettings);
        
        emit(SettingsLoaded(
          settings: updatedSettings,
          isPremiumUser: currentState.isPremiumUser,
        ));
      } catch (e) {
        emit(SettingsError('Failed to toggle save original: ${e.toString()}'));
        emit(state);
      }
    }
  }

  Future<void> _onClearCompressionHistory(
    ClearCompressionHistoryEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      try {
        await _storageService.clearCompressionHistory();
        emit(SettingsLoaded(
          settings: (state as SettingsLoaded).settings,
          isPremiumUser: (state as SettingsLoaded).isPremiumUser,
        ));
      } catch (e) {
        emit(SettingsError('Failed to clear compression history: ${e.toString()}'));
        emit(state);
      }
    }
  }

  void _onNavigateToSubscription(
    NavigateToSubscriptionEvent event,
    Emitter<SettingsState> emit,
  ) {
    emit(NavigateToSubscription());
    // After navigation, we want to revert back to the settings state
    if (state is SettingsLoaded) {
      emit(state);
    } else {
      add(LoadSettingsEvent());
    }
  }
}