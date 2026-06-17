import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:estatetrack1/config/api_config.dart';

/// App-wide preferences persisted locally (theme, login, API URL).
class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const _themeModeKey = 'theme_mode';
  static const _lastUserIdKey = 'last_user_id';
  static const _apiBaseUrlKey = 'api_base_url';
  static const _leaseRemindersKey = 'lease_reminders_enabled';

  ThemeMode themeMode = ThemeMode.system;
  String? lastUserId;
  String? apiBaseUrl;
  bool leaseRemindersEnabled = true;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode = _decodeThemeMode(prefs.getString(_themeModeKey));
    lastUserId = prefs.getString(_lastUserIdKey);
    apiBaseUrl = prefs.getString(_apiBaseUrlKey);
    leaseRemindersEnabled = prefs.getBool(_leaseRemindersKey) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode == mode) return;
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _encodeThemeMode(mode));
  }

  Future<void> setLastUserId(String userId) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return;
    lastUserId = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserIdKey, trimmed);
  }

  Future<void> setApiBaseUrl(String? url) async {
    final trimmed = url?.trim();
    apiBaseUrl = trimmed?.isEmpty == true ? null : trimmed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (apiBaseUrl == null) {
      await prefs.remove(_apiBaseUrlKey);
    } else {
      await prefs.setString(_apiBaseUrlKey, apiBaseUrl!);
    }
  }

  Future<void> resetApiBaseUrl() => setApiBaseUrl(null);

  Future<void> setLeaseRemindersEnabled(bool enabled) async {
    if (leaseRemindersEnabled == enabled) return;
    leaseRemindersEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_leaseRemindersKey, enabled);
  }

  String get effectiveApiBaseUrl => apiBaseUrl ?? ApiConfig.defaultBaseUrl;

  static ThemeMode _decodeThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _encodeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
