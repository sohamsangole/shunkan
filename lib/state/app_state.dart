import 'package:flutter/foundation.dart';
import '../models/daily_activity.dart';
import '../models/jlpt_level.dart';
import '../models/kanji.dart';
import '../models/learning_record.dart';
import '../models/user_settings.dart';
import '../services/kanji_repository.dart';
import '../services/kanji_selector.dart';
import '../services/lockscreen_manager.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// Central application state manager.
/// Enforces complete isolation between user settings (JLPT level)
/// and learning history, ensuring level switches never wipe progress.
class AppState extends ChangeNotifier {
  final StorageService _storageService;
  final KanjiRepository _kanjiRepository;
  final KanjiSelectorService _selectorService;
  final NotificationService _notificationService;

  UserSettings _settings = const UserSettings();
  Map<String, LearningRecord> _learningHistory = {};
  Map<String, DailyActivity> _dailyActivities = {};
  TelemetryData _telemetry = const TelemetryData();
  bool _isLoading = true;

  AppState({
    required StorageService storageService,
    required KanjiRepository kanjiRepository,
    required KanjiSelectorService selectorService,
    required NotificationService notificationService,
  })  : _storageService = storageService,
        _kanjiRepository = kanjiRepository,
        _selectorService = selectorService,
        _notificationService = notificationService;

  // --- Getters ---

  UserSettings get settings => _settings;
  JLPTLevel? get currentLevel => _settings.jlptLevel;
  bool get isOnboardingCompleted => _settings.onboardingCompleted;
  bool get isLoading => _isLoading;
  Map<String, LearningRecord> get learningHistory =>
      Map.unmodifiable(_learningHistory);
  Map<String, DailyActivity> get dailyActivities =>
      Map.unmodifiable(_dailyActivities);
  TelemetryData get telemetry => _telemetry;

  KanjiRepository get repository => _kanjiRepository;
  KanjiSelectorService get selectorService => _selectorService;

  /// Current eligible Kanji pool derived dynamically from cumulative progression
  List<Kanji> get currentEligiblePool {
    if (_settings.jlptLevel == null) return [];
    return _selectorService.getEligiblePool(_settings.jlptLevel!);
  }

  /// List of Kanji models encountered today
  List<Kanji> get kanjisViewedToday {
    final result = <Kanji>[];
    final seenIds = <String>{};

    for (final id in _telemetry.kanjiIdsToday) {
      if (seenIds.contains(id)) continue;
      Kanji? k = _kanjiRepository.getById(id);
      if (k == null) {
        try {
          k = _kanjiRepository.getAll().firstWhere(
                (item) => item.character == id || item.id == id,
              );
        } catch (_) {}
      }
      if (k != null) {
        seenIds.add(id);
        result.add(k);
      }
    }
    return result;
  }

  /// Percentage (0.0 to 1.0) of active pool covered today
  double get todayPoolCoverage {
    final pool = currentEligiblePool;
    if (pool.isEmpty) return 0.0;
    final poolIds = pool.map((k) => k.id).toSet();
    final poolChars = pool.map((k) => k.character).toSet();
    final seenCount = _telemetry.kanjiIdsToday
        .where((id) => poolIds.contains(id) || poolChars.contains(id))
        .toSet()
        .length;
    return (seenCount / pool.length).clamp(0.0, 1.0);
  }

  /// Count of active pool Kanji seen today
  int get todayPoolSeenCount {
    final pool = currentEligiblePool;
    if (pool.isEmpty) return 0;
    final poolIds = pool.map((k) => k.id).toSet();
    final poolChars = pool.map((k) => k.character).toSet();
    return _telemetry.kanjiIdsToday
        .where((id) => poolIds.contains(id) || poolChars.contains(id))
        .toSet()
        .length;
  }

  /// Set of unique Kanji IDs encountered during the current week
  Set<String> get kanjiIdsThisWeek {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final result = <String>{};
    result.addAll(_telemetry.kanjiIdsToday);

    for (final entry in _dailyActivities.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date != null && !date.isBefore(startOfWeek)) {
        result.addAll(entry.value.kanjiIds);
      }
    }
    return result;
  }

  /// Percentage (0.0 to 1.0) of active pool covered this week
  double get thisWeekPoolCoverage {
    final pool = currentEligiblePool;
    if (pool.isEmpty) return 0.0;
    return (thisWeekPoolSeenCount / pool.length).clamp(0.0, 1.0);
  }

  /// Count of active pool Kanji seen this week
  int get thisWeekPoolSeenCount {
    final pool = currentEligiblePool;
    if (pool.isEmpty) return 0;
    final poolIds = pool.map((k) => k.id).toSet();
    final poolChars = pool.map((k) => k.character).toSet();
    final seen = kanjiIdsThisWeek;
    return seen
        .where((id) => poolIds.contains(id) || poolChars.contains(id))
        .length;
  }

  /// Initialize state from local persistent storage
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _storageService.loadSettings();
      _learningHistory = await _storageService.loadLearningHistory();
      _dailyActivities = await _storageService.loadDailyActivities();
      await _notificationService.initialize();
      await _notificationService.requestPermissions();

      if (_settings.onboardingCompleted && _settings.jlptLevel != null) {
        if (_settings.lockscreenRefreshEnabled) {
          await LockscreenManager.updatePool(currentEligiblePool);
          await LockscreenManager.startService();
        }
      }
      await refreshTelemetry();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Refreshes passive habit telemetry from native service and persists today's activity
  Future<void> refreshTelemetry() async {
    try {
      final data = await LockscreenManager.getTelemetry();
      _telemetry = data;

      final now = DateTime.now();
      final todayStr =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      if (data.glancesToday > 0 || data.kanjiIdsToday.isNotEmpty) {
        final activity = DailyActivity(
          date: todayStr,
          glances: data.glancesToday,
          uniqueKanji: data.uniqueKanjiToday,
          estimatedSeconds: data.estimatedSecondsToday,
          kanjiIds: data.kanjiIdsToday,
        );
        _dailyActivities[todayStr] = activity;
        await _storageService.saveDailyActivity(activity);
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Records an active kanji view/review from within the app
  Future<void> recordKanjiView(String kanjiId) async {
    // Record in learning history
    await recordReview(kanjiId, isCorrect: true);
    // Refresh telemetry to ensure consistency
    await refreshTelemetry();
  }

  /// First launch: Save initial JLPT level and complete onboarding
  Future<void> completeOnboarding(JLPTLevel selectedLevel) async {
    _settings = _settings.copyWith(
      jlptLevel: selectedLevel,
      onboardingCompleted: true,
    );
    await _storageService.saveSettings(_settings);

    // Refresh notification schedule with new level pool
    await _notificationService.refreshNotificationScheduleForNewLevel(
      selectedLevel,
      _settings.notificationIntervalMinutes,
    );

    if (_settings.lockscreenRefreshEnabled) {
      await LockscreenManager.updatePool(currentEligiblePool, refreshImmediate: true);
      await LockscreenManager.startService();
    }

    notifyListeners();
  }

  /// Change JLPT level from Settings at any time.
  /// Changing level immediately updates the notification pool.
  /// IMPORTANT: Learning history is preserved and NOT deleted.
  Future<void> updateLevel(JLPTLevel newLevel) async {
    if (_settings.jlptLevel == newLevel) return;

    _settings = _settings.copyWith(jlptLevel: newLevel);
    await _storageService.saveSettings(_settings);

    // Immediately update the notification scheduler with the new pool
    await _notificationService.refreshNotificationScheduleForNewLevel(
      newLevel,
      _settings.notificationIntervalMinutes,
    );

    if (_settings.lockscreenRefreshEnabled) {
      await LockscreenManager.updatePool(currentEligiblePool, refreshImmediate: true);
    }

    // Explicitly note: _learningHistory remains completely untouched
    notifyListeners();
  }

  /// Toggles automatic lock-screen refreshing service
  Future<void> toggleLockscreenRefresh(bool enabled) async {
    _settings = _settings.copyWith(lockscreenRefreshEnabled: enabled);
    await _storageService.saveSettings(_settings);

    if (enabled) {
      await LockscreenManager.updatePool(currentEligiblePool, refreshImmediate: true);
      await LockscreenManager.startService();
    } else {
      await LockscreenManager.stopService();
    }
    notifyListeners();
  }

  /// Trigger a test lock-screen notification right now
  Future<Kanji?> triggerTestNotification() async {
    if (_settings.jlptLevel == null) return null;
    return await _notificationService
        .triggerImmediateKanjiNotification(_settings.jlptLevel!);
  }

  /// Record user interaction / review for a Kanji
  Future<void> recordReview(String kanjiId, {required bool isCorrect}) async {
    final existing = _learningHistory[kanjiId] ??
        LearningRecord(
          kanjiId: kanjiId,
          lastSeenAt: DateTime.now(),
        );

    final updated = existing.copyWith(
      timesSeen: existing.timesSeen + 1,
      timesTested: existing.timesTested + 1,
      timesCorrect: isCorrect ? existing.timesCorrect + 1 : existing.timesCorrect,
      lastSeenAt: DateTime.now(),
      masteryScore: ((existing.timesCorrect + (isCorrect ? 1 : 0)) /
              (existing.timesTested + 1))
          .clamp(0.0, 1.0),
    );

    _learningHistory[kanjiId] = updated;
    await _storageService.saveLearningRecord(updated);
    notifyListeners();
  }
}
