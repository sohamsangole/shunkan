import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/jlpt_level.dart';
import '../models/kanji.dart';
import 'kanji_selector.dart';

/// Notification service managing lock-screen notifications for Kanji learning.
class NotificationService {
  static const String channelId = 'kanji_lock_screen_v2';
  static const String channelName = 'Kanji Flashcard Review';
  static const String channelDescription =
      'Shows Kanji review flashcards on lock screen';

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final KanjiSelectorService _selectorService;

  NotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    required KanjiSelectorService selectorService,
  })  : _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
        _selectorService = selectorService;

  /// Initializes notification plugin and android channels.
  Future<bool> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      final initialized = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle tap on notification
        },
      );
      return initialized ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests notification permissions on platforms that require it (Android 13+, iOS).
  Future<bool?> requestPermissions() async {
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        return await androidPlatform.requestNotificationsPermission();
      }

      final iosPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlatform != null) {
        return await iosPlatform.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (_) {}
    return true;
  }

  /// Immediately dispatches a lock-screen notification with a random Kanji
  /// from the user's current eligible pool as a high-resolution visual flashcard.
  Future<Kanji?> triggerImmediateKanjiNotification(JLPTLevel userLevel) async {
    final kanji = _selectorService.selectRandomKanjiForLevel(userLevel);
    if (kanji == null) return null;

    // Build compound examples in Hiragana (No Katakana!)
    final onExamplesHtml = kanji.onExamples.isNotEmpty
        ? kanji.onExamples.take(2).map((e) => '• ${e.word} (${e.reading}) — ${e.meaning}').join('<br>')
        : '';
    final kunExamplesHtml = kanji.kunExamples.isNotEmpty
        ? kanji.kunExamples.take(2).map((e) => '• ${e.word} (${e.reading}) — ${e.meaning}').join('<br>')
        : '';

    // BigText body: Clean alignment, proper spacing, NO duplicate kanji, NO blue image
    final bodyHtml = StringBuffer()
      ..write('<b>MEANING:</b> ${kanji.meaningsDisplay.toUpperCase()}<br><br>')
      ..write('<b>ON:</b> ${kanji.onyomiHiraganaDisplay}');
    if (onExamplesHtml.isNotEmpty) {
      bodyHtml.write('<br>$onExamplesHtml');
    }
    bodyHtml.write('<br><br><b>KUN:</b> ${kanji.kunyomiDisplay}');
    if (kunExamplesHtml.isNotEmpty) {
      bodyHtml.write('<br>$kunExamplesHtml');
    }

    // Title line: EXACT same sizes with <sup> to vertically center the English meaning to the middle
    final titleHtml = '<big><big><big><big><big><big><big><big><big><big><b>${kanji.character}</b></big></big></big></big></big></big></big></big></big></big> &nbsp;&nbsp;&nbsp; <sup><big><big><big><big><b>${kanji.primaryMeaning.toUpperCase()}</b></big></big></big></big></sup>';

    final bigTextStyle = BigTextStyleInformation(
      bodyHtml.toString(),
      htmlFormatBigText: true,
      contentTitle: titleHtml,
      htmlFormatContentTitle: true,
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public, // Visible on lock screen
      styleInformation: bigTextStyle, // NO largeIcon (removes the little blue image!)
      ticker: '${kanji.character}  ${kanji.primaryMeaning}',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(
        1001,
        titleHtml,
        'MEANING: ${kanji.meaningsDisplay.toUpperCase()}',
        details,
        payload: kanji.id,
      );
    } catch (_) {}

    return kanji;
  }

  /// Cancels pending notifications and reschedules them when the user changes levels.
  Future<void> refreshNotificationScheduleForNewLevel(
      JLPTLevel newLevel, int intervalMinutes) async {
    try {
      await _notificationsPlugin.cancelAll();
      // Future periodic or workmanager alarms would be refreshed here
      // with new candidates exclusively selected from the new cumulative pool.
    } catch (_) {}
  }
}
