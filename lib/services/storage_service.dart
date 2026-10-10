import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';

/// Handles persistent local storage for user settings.
class StorageService {
  static const String _keySettings = 'app_user_settings';

  final SharedPreferences? _prefs;

  // In-memory fallback cache
  final Map<String, dynamic> _memoryCache = {};

  StorageService([this._prefs]);

  static Future<StorageService> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clean up legacy unused keys if they exist on disk
      await prefs.remove('app_user_learning_history');
      await prefs.remove('app_daily_activities');
      return StorageService(prefs);
    } catch (_) {
      // In-memory mock if SharedPreferences is unavailable in tests
      return StorageService(null);
    }
  }

  // --- User Settings ---

  Future<UserSettings> loadSettings() async {
    try {
      String? jsonStr;
      if (_prefs != null) {
        jsonStr = _prefs!.getString(_keySettings);
      } else {
        jsonStr = _memoryCache[_keySettings] as String?;
      }

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        return UserSettings.fromJson(map);
      }
    } catch (_) {}
    return const UserSettings();
  }

  Future<void> saveSettings(UserSettings settings) async {
    final jsonStr = jsonEncode(settings.toJson());
    if (_prefs != null) {
      await _prefs!.setString(_keySettings, jsonStr);
    } else {
      _memoryCache[_keySettings] = jsonStr;
    }
  }
}
