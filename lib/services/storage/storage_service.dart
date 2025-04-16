import 'dart:convert';
import 'package:photoshrink/core/constants/app_constants.dart';
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
  final SharedPreferences _preferences;
  
  StorageServiceImpl(this._preferences);
  
  @override
  Future<bool> isOnboardingCompleted() async {
    return _preferences.getBool(AppConstants.onboardingCompletedKey) ?? false;
  }
  
  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await _preferences.setBool(AppConstants.onboardingCompletedKey, completed);
  }
  
  @override
  Future<UserSettings> getUserSettings() async {
    final String? settingsJson = _preferences.getString(AppConstants.userSettingsKey);
    if (settingsJson == null) {
      return UserSettings.defaultSettings();
    }
    return UserSettings.fromJson(jsonDecode(settingsJson));
  }
  
  @override
  Future<void> saveUserSettings(UserSettings settings) async {
    await _preferences.setString(
      AppConstants.userSettingsKey, 
      jsonEncode(settings.toJson())
    );
  }
  
  @override
  Future<List<CompressionHistory>> getCompressionHistory() async {
    final String? historyJson = _preferences.getString(AppConstants.compressionHistoryKey);
    if (historyJson == null) {
      return [];
    }
    
    final List<dynamic> historyList = jsonDecode(historyJson);
    return historyList
        .map((item) => CompressionHistory.fromJson(item))
        .toList();
  }
  
  @override
  Future<void> addCompressionHistory(CompressionHistory history) async {
    final List<CompressionHistory> currentHistory = await getCompressionHistory();
    currentHistory.add(history);
    
    // Keep only the last 50 items to avoid excessive storage
    if (currentHistory.length > 50) {
      currentHistory.removeRange(0, currentHistory.length - 50);
    }
    
    await _preferences.setString(
      AppConstants.compressionHistoryKey,
      jsonEncode(currentHistory.map((e) => e.toJson()).toList())
    );
  }
  
  @override
  Future<void> clearCompressionHistory() async {
    await _preferences.remove(AppConstants.compressionHistoryKey);
  }
  
  @override
  Future<int> getDefaultCompressionLevel() async {
    return _preferences.getInt(AppConstants.defaultCompressionLevelKey) ?? 
           AppConstants.mediumQuality;
  }
  
  @override
  Future<void> setDefaultCompressionLevel(int level) async {
    await _preferences.setInt(AppConstants.defaultCompressionLevelKey, level);
  }
  
  @override
  Future<bool> isPremiumUser() async {
    return _preferences.getBool('is_premium_user') ?? false;
  }
  
  @override
  Future<void> setPremiumUser(bool isPremium) async {
    await _preferences.setBool('is_premium_user', isPremium);
  }
}