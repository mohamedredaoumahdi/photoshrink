import 'dart:convert';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:photoshrink/data/models/compression_history.dart';
import 'package:photoshrink/data/models/user_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageService {
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool completed);
  
  Future<UserSettings> getUserSettings();
  Future<void> saveUserSettings(UserSettings settings);
  
  Future<List<CompressionHistory>> getCompressionHistory();
  Future<void> addCompressionHistory(CompressionHistory history);
  Future<void> clearCompressionHistory();
  
  Future<int> getDefaultCompressionLevel();
  Future<void> setDefaultCompressionLevel(int level);
  
  Future<bool> isPremiumUser();
  Future<void> setPremiumUser(bool isPremium);
}

class StorageServiceImpl implements StorageService {
  static const String TAG = 'StorageService';
  
  final SharedPreferences _preferences;
  
  StorageServiceImpl(this._preferences) {
    LoggerUtil.i(TAG, 'StorageService initialized');
  }
  
  @override
  Future<bool> isOnboardingCompleted() async {
    final result = _preferences.getBool(AppConstants.onboardingCompletedKey) ?? false;
    LoggerUtil.d(TAG, 'Onboarding completed: $result');
    return result;
  }
  
  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    LoggerUtil.d(TAG, 'Setting onboarding completed: $completed');
    await _preferences.setBool(AppConstants.onboardingCompletedKey, completed);
    LoggerUtil.service(TAG, 'Onboarding status set to $completed');
  }
  
  @override
  Future<UserSettings> getUserSettings() async {
    LoggerUtil.d(TAG, 'Getting user settings');
    final String? settingsJson = _preferences.getString(AppConstants.userSettingsKey);
    if (settingsJson == null) {
      LoggerUtil.d(TAG, 'No saved settings found, using defaults');
      return UserSettings.defaultSettings();
    }
    
    try {
      final settings = UserSettings.fromJson(jsonDecode(settingsJson));
      LoggerUtil.d(TAG, 'User settings loaded successfully');
      return settings;
    } catch (e) {
      LoggerUtil.e(TAG, 'Error parsing settings: $e');
      return UserSettings.defaultSettings();
    }
  }
  
  @override
  Future<void> saveUserSettings(UserSettings settings) async {
    LoggerUtil.d(TAG, 'Saving user settings');
    try {
      await _preferences.setString(
        AppConstants.userSettingsKey, 
        jsonEncode(settings.toJson())
      );
      LoggerUtil.service(TAG, 'User settings saved successfully');
    } catch (e) {
      LoggerUtil.e(TAG, 'Error saving settings: $e');
      throw e;
    }
  }
  
  @override
  Future<List<CompressionHistory>> getCompressionHistory() async {
    LoggerUtil.d(TAG, 'Getting compression history');
    final String? historyJson = _preferences.getString(AppConstants.compressionHistoryKey);
    if (historyJson == null) {
      LoggerUtil.d(TAG, 'No compression history found');
      return [];
    }
    
    try {
      final List<dynamic> historyList = jsonDecode(historyJson);
      final history = historyList
          .map((item) => CompressionHistory.fromJson(item))
          .toList();
      
      LoggerUtil.d(TAG, 'Loaded ${history.length} compression history items');
      return history;
    } catch (e) {
      LoggerUtil.e(TAG, 'Error parsing compression history: $e');
      return [];
    }
  }
  
  @override
  Future<void> addCompressionHistory(CompressionHistory history) async {
    LoggerUtil.d(TAG, 'Adding new compression history item');
    try {
      final List<CompressionHistory> currentHistory = await getCompressionHistory();
      currentHistory.add(history);
      
      // Keep only the last 50 items to avoid excessive storage
      if (currentHistory.length > 50) {
        LoggerUtil.d(TAG, 'Trimming compression history to last 50 items');
        currentHistory.removeRange(0, currentHistory.length - 50);
      }
      
      await _preferences.setString(
        AppConstants.compressionHistoryKey,
        jsonEncode(currentHistory.map((e) => e.toJson()).toList())
      );
      
      LoggerUtil.service(TAG, 'Compression history updated (${currentHistory.length} items)');
    } catch (e) {
      LoggerUtil.e(TAG, 'Error adding compression history: $e');
      throw e;
    }
  }
  
  @override
  Future<void> clearCompressionHistory() async {
    LoggerUtil.d(TAG, 'Clearing compression history');
    try {
      await _preferences.remove(AppConstants.compressionHistoryKey);
      LoggerUtil.service(TAG, 'Compression history cleared');
    } catch (e) {
      LoggerUtil.e(TAG, 'Error clearing compression history: $e');
      throw e;
    }
  }
  
  @override
  Future<int> getDefaultCompressionLevel() async {
    final level = _preferences.getInt(AppConstants.defaultCompressionLevelKey) ?? 
                  AppConstants.mediumQuality;
    LoggerUtil.d(TAG, 'Default compression level: $level');
    return level;
  }
  
  @override
  Future<void> setDefaultCompressionLevel(int level) async {
    LoggerUtil.d(TAG, 'Setting default compression level to $level');
    try {
      await _preferences.setInt(AppConstants.defaultCompressionLevelKey, level);
      LoggerUtil.service(TAG, 'Default compression level set to $level');
    } catch (e) {
      LoggerUtil.e(TAG, 'Error setting default compression level: $e');
      throw e;
    }
  }
  
  @override
  Future<bool> isPremiumUser() async {
    final isPremium = _preferences.getBool('is_premium_user') ?? false;
    LoggerUtil.d(TAG, 'User premium status: $isPremium');
    return isPremium;
  }
  
  @override
  Future<void> setPremiumUser(bool isPremium) async {
    LoggerUtil.d(TAG, 'Setting user premium status to $isPremium');
    try {
      await _preferences.setBool('is_premium_user', isPremium);
      LoggerUtil.service(TAG, 'User premium status updated to $isPremium');
    } catch (e) {
      LoggerUtil.e(TAG, 'Error setting premium status: $e');
      throw e;
    }
  }
}