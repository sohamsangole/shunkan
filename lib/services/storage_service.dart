import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_activity.dart';
import '../models/learning_record.dart';
import '../models/user_settings.dart';

/// Handles persistent local storage for settings, learning history, and daily habit metrics.
/// Guarantees that user settings (such as JLPT level) are stored independently
/// from user learning history.
class StorageService {
  static const String _keySettings = 'app_user_settings';
  static const String _keyLearningHistory = 'app_user_learning_history';
  static const String _keyDailyActivities = 'app_daily_activities';

  final SharedPreferences? _prefs;

  // In-memory fallback cache
  final Map<String, dynamic> _memoryCache = {};

  StorageService([this._prefs]);

  static Future<StorageService> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
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

  // --- Learning History (Completely isolated) ---

  Future<Map<String, LearningRecord>> loadLearningHistory() async {
    try {
      String? jsonStr;
      if (_prefs != null) {
        jsonStr = _prefs!.getString(_keyLearningHistory);
      } else {
        jsonStr = _memoryCache[_keyLearningHistory] as String?;
      }

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> rawMap = jsonDecode(jsonStr);
        return rawMap.map(
          (key, value) => MapEntry(
            key,
            LearningRecord.fromJson(value as Map<String, dynamic>),
          ),
        );
      }
    } catch (_) {}
    return {};
  }

  Future<void> saveLearningRecord(LearningRecord record) async {
    final currentHistory = await loadLearningHistory();
    currentHistory[record.kanjiId] = record;
    await _saveAllHistory(currentHistory);
  }

  Future<void> _saveAllHistory(Map<String, LearningRecord> history) async {
    final rawMap = history.map((key, value) => MapEntry(key, value.toJson()));
    final jsonStr = jsonEncode(rawMap);
    if (_prefs != null) {
      await _prefs!.setString(_keyLearningHistory, jsonStr);
    } else {
      _memoryCache[_keyLearningHistory] = jsonStr;
    }
  }

  // --- Daily Activity & Exposure Time Tracking ---

  Future<Map<String, DailyActivity>> loadDailyActivities() async {
    try {
      String? jsonStr;
      if (_prefs != null) {
        jsonStr = _prefs!.getString(_keyDailyActivities);
      } else {
        jsonStr = _memoryCache[_keyDailyActivities] as String?;
      }

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> rawMap = jsonDecode(jsonStr);
        return rawMap.map(
          (key, value) => MapEntry(
            key,
            DailyActivity.fromJson(value as Map<String, dynamic>),
          ),
        );
      }
    } catch (_) {}
    return {};
  }

  Future<void> saveDailyActivity(DailyActivity activity) async {
    final activities = await loadDailyActivities();
    activities[activity.date] = activity;
    final rawMap = activities.map((key, value) => MapEntry(key, value.toJson()));
    final jsonStr = jsonEncode(rawMap);
    if (_prefs != null) {
      await _prefs!.setString(_keyDailyActivities, jsonStr);
    } else {
      _memoryCache[_keyDailyActivities] = jsonStr;
    }
  }
}
