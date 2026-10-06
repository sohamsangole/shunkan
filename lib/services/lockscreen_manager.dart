import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/kanji.dart';

/// Bridges Flutter with the native Android LockscreenKanjiService.
class LockscreenManager {
  static const _channel =
      MethodChannel('com.example.kanji_learning_app/lockscreen');

  /// Starts the persistent lock-screen review service.
  static Future<void> startService() async {
    try {
      await _channel.invokeMethod('startLockscreenService');
    } catch (_) {}
  }

  /// Stops the persistent lock-screen review service.
  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopLockscreenService');
    } catch (_) {}
  }

  /// Checks if the native service is currently running.
  static Future<bool> isServiceRunning() async {
    try {
      final res = await _channel.invokeMethod<bool>('isServiceRunning');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Synchronizes the active eligible Kanji pool with the native service.
  static Future<void> updatePool(
    List<Kanji> kanjiList, {
    bool refreshImmediate = false,
  }) async {
    try {
      final listJson = kanjiList.map((k) => {
        'id': k.id,
        'character': k.character,
        'primaryMeaning': k.primaryMeaning,
        'meaningsDisplay': k.meaningsDisplay,
        'onyomiDisplay': k.onyomiHiraganaDisplay,
        'kunyomiDisplay': k.kunyomiDisplay,
        'onExamples': k.onExamples.map((e) => {
          'word': e.word,
          'reading': e.reading,
          'meaning': e.meaning,
        }).toList(),
        'kunExamples': k.kunExamples.map((e) => {
          'word': e.word,
          'reading': e.reading,
          'meaning': e.meaning,
        }).toList(),
      }).toList();

      final jsonString = jsonEncode(listJson);
      await _channel.invokeMethod('updateKanjiPool', {
        'kanjiJson': jsonString,
        'refreshImmediate': refreshImmediate,
      });
    } catch (_) {}
  }

  /// Resets lockscreen glance counts and deck in native storage (e.g. when JLPT level changes).
  static Future<void> resetGlanceCounts() async {
    try {
      await _channel.invokeMethod('resetGlanceCounts');
    } catch (_) {}
  }

  /// Fetches passive habit telemetry from the native lockscreen service.
  static Future<TelemetryData> getTelemetry() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('getTelemetry');
      if (res != null) {
        return TelemetryData.fromMap(res);
      }
    } catch (_) {}
    return const TelemetryData();
  }

  /// Sets a listener for notification clicks that specify a Kanji to open.
  static void setKanjiOpenHandler(Function(String kanjiId) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onOpenKanji') {
        final id = call.arguments as String?;
        if (id != null && id.isNotEmpty) {
          handler(id);
        }
      }
    });
  }

  /// Checks if the app was launched by tapping a Kanji notification.
  static Future<String?> getPendingKanjiId() async {
    try {
      final res = await _channel.invokeMethod<String>('getPendingKanji');
      return res;
    } catch (_) {
      return null;
    }
  }
}

/// Passive glance and encounter metrics recorded on lock-screen triggers.
class TelemetryData {
  final int glancesToday;
  final int uniqueKanjiToday;
  final List<String> kanjiIdsToday;
  final Map<String, int> kanjiGlanceCountsToday;
  final int streakDays;
  final int cyclesCompleted;
  final int windowStartMs;
  final int windowSeenCount;
  final String lastKanji;
  final String lastMeaning;

  const TelemetryData({
    this.glancesToday = 0,
    this.uniqueKanjiToday = 0,
    this.kanjiIdsToday = const [],
    this.kanjiGlanceCountsToday = const {},
    this.streakDays = 1,
    this.cyclesCompleted = 0,
    this.windowStartMs = 0,
    this.windowSeenCount = 0,
    this.lastKanji = '',
    this.lastMeaning = '',
  });

  /// Estimated passive viewing time in seconds (averaging ~4 seconds per glance)
  int get estimatedSecondsToday => glancesToday * 4;

  factory TelemetryData.fromMap(Map<dynamic, dynamic> map) {
    final rawIds = map['kanjiIdsToday'] as List<dynamic>?;
    final ids = rawIds?.map((e) => e.toString()).toList() ?? const [];

    final rawCounts = map['kanjiGlanceCountsToday'] as Map<dynamic, dynamic>?;
    final counts = <String, int>{};
    if (rawCounts != null) {
      rawCounts.forEach((k, v) {
        counts[k.toString()] = (v as num?)?.toInt() ?? 1;
      });
    }

    return TelemetryData(
      glancesToday: (map['glancesToday'] as num?)?.toInt() ?? 0,
      uniqueKanjiToday: (map['uniqueKanjiToday'] as num?)?.toInt() ?? 0,
      kanjiIdsToday: ids,
      kanjiGlanceCountsToday: counts,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 1,
      cyclesCompleted: (map['cyclesCompleted'] as num?)?.toInt() ?? 0,
      windowStartMs: (map['windowStartMs'] as num?)?.toInt() ?? 0,
      windowSeenCount: (map['windowSeenCount'] as num?)?.toInt() ?? 0,
      lastKanji: map['lastKanji'] as String? ?? '',
      lastMeaning: map['lastMeaning'] as String? ?? '',
    );
  }
}

