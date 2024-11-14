import 'package:flutter/material.dart';

import '../Helper/SettingConfigHelper.dart';
import '../models/SettingsConfigModel.dart';

class ConfigProvider with ChangeNotifier {
  SettingConfigModel? _config;
  final SettingConfigDataHelper _configDataHelper = SettingConfigDataHelper();

  SettingConfigModel? get config => _config;

  // Load the configuration settings from Firestore
  Future<void> loadConfig() async {
    _config = await _configDataHelper.getSettingConfig();
    notifyListeners();
  }

  // Update the entire configuration settings
  Future<void> updateConfig(SettingConfigModel newConfig) async {
    await _configDataHelper.updateSettingConfig(newConfig);
    _config = newConfig;
    notifyListeners();
  }

  // Set the subscription status and update Firestore
  Future<void> setSubscriptionActive(bool isActive) async {
    if (_config != null) {
      _config = SettingConfigModel(
        isSubscriptionActive: isActive,
        lastUpdated: DateTime.now().toIso8601String(),
        schedulerEnabled: _config!.schedulerEnabled,
        startedAt: _config!.startedAt,
        startedBy: _config!.startedBy,
        offensiveWords: _config!.offensiveWords,
      );
      await _configDataHelper.updateSettingConfig(_config!);
      notifyListeners();
    }
  }

  // Add a new offensive word to the list and update Firestore
  Future<void> addOffensiveWord(String word) async {
    if (_config != null) {
      final updatedWords = List<String>.from(_config!.offensiveWords)..add(word);
      _config = SettingConfigModel(
        isSubscriptionActive: _config!.isSubscriptionActive,
        lastUpdated: DateTime.now().toIso8601String(),
        schedulerEnabled: _config!.schedulerEnabled,
        startedAt: _config!.startedAt,
        startedBy: _config!.startedBy,
        offensiveWords: updatedWords,
      );
      await _configDataHelper.updateSettingConfig(_config!);
      notifyListeners();
    }
  }

  // Remove an offensive word from the list and update Firestore
  Future<void> removeOffensiveWord(String word) async {
    if (_config != null) {
      final updatedWords = List<String>.from(_config!.offensiveWords)..remove(word);
      _config = SettingConfigModel(
        isSubscriptionActive: _config!.isSubscriptionActive,
        lastUpdated: DateTime.now().toIso8601String(),
        schedulerEnabled: _config!.schedulerEnabled,
        startedAt: _config!.startedAt,
        startedBy: _config!.startedBy,
        offensiveWords: updatedWords,
      );
      await _configDataHelper.updateSettingConfig(_config!);
      notifyListeners();
    }
  }
}
