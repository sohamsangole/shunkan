import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_learning_app/models/daily_activity.dart';
import 'package:kanji_learning_app/models/jlpt_level.dart';
import 'package:kanji_learning_app/models/kanji.dart';
import 'package:kanji_learning_app/services/kanji_repository.dart';
import 'package:kanji_learning_app/services/kanji_selector.dart';
import 'package:kanji_learning_app/services/notification_service.dart';
import 'package:kanji_learning_app/services/storage_service.dart';
import 'package:kanji_learning_app/state/app_state.dart';

List<Kanji> loadTestKanji() {
  final file = File('assets/data/kanji.json');
  final decoded = jsonDecode(file.readAsStringSync()) as List;
  return decoded.map((i) => Kanji.fromJson(i as Map<String, dynamic>)).toList();
}

void main() {
  final testData = loadTestKanji();

  group('JLPT Level Progression and Cumulative Coverage', () {
    test('N5 cumulative coverage is only N5', () {
      expect(JLPTLevel.n5.cumulativeLevels, equals([JLPTLevel.n5]));
    });

    test('N4 cumulative coverage is N5 and N4', () {
      expect(
        JLPTLevel.n4.cumulativeLevels,
        equals([JLPTLevel.n5, JLPTLevel.n4]),
      );
    });

    test('N3 cumulative coverage is N5, N4, and N3', () {
      expect(
        JLPTLevel.n3.cumulativeLevels,
        equals([JLPTLevel.n5, JLPTLevel.n4, JLPTLevel.n3]),
      );
    });

    test('N2 cumulative coverage is N5, N4, N3, and N2', () {
      expect(
        JLPTLevel.n2.cumulativeLevels,
        equals([JLPTLevel.n5, JLPTLevel.n4, JLPTLevel.n3, JLPTLevel.n2]),
      );
    });

    test('N1 cumulative coverage includes all 5 levels', () {
      expect(
        JLPTLevel.n1.cumulativeLevels,
        equals([
          JLPTLevel.n5,
          JLPTLevel.n4,
          JLPTLevel.n3,
          JLPTLevel.n2,
          JLPTLevel.n1,
        ]),
      );
    });
  });

  group('Kanji Selector and Cumulative Filtering Pool', () {
    late KanjiRepository repository;
    late KanjiSelectorService selector;

    setUp(() {
      repository = KanjiRepository(initialData: testData);
      selector = KanjiSelectorService(repository: repository);
    });

    test('N5 pool only contains N5 Kanji', () {
      final pool = selector.getEligiblePool(JLPTLevel.n5);
      expect(pool, isNotEmpty);
      for (final kanji in pool) {
        expect(kanji.metadata.jlpt, equals(JLPTLevel.n5));
      }
    });

    test('N4 pool contains only N5 and N4 Kanji', () {
      final pool = selector.getEligiblePool(JLPTLevel.n4);
      expect(pool, isNotEmpty);
      for (final kanji in pool) {
        expect(
          [JLPTLevel.n5, JLPTLevel.n4].contains(kanji.metadata.jlpt),
          isTrue,
        );
      }
    });

    test('N4 pool contains N5 and N4 Kanji, and NO N3, N2 or N1', () {
      final pool = selector.getEligiblePool(JLPTLevel.n4);
      expect(pool, isNotEmpty);
      final levelsInPool = pool.map((k) => k.metadata.jlpt).toSet();
      expect(levelsInPool.contains(JLPTLevel.n3), isFalse);
      expect(levelsInPool.contains(JLPTLevel.n2), isFalse);
      expect(levelsInPool.contains(JLPTLevel.n1), isFalse);
      expect(levelsInPool.contains(JLPTLevel.n5), isTrue);
      expect(levelsInPool.contains(JLPTLevel.n4), isTrue);
    });

    test('Random selection strictly picks from the user eligible pool', () {
      for (int i = 0; i < 50; i++) {
        final kanji = selector.selectRandomKanjiForLevel(JLPTLevel.n5);
        expect(kanji, isNotNull);
        expect(kanji!.metadata.jlpt, equals(JLPTLevel.n5));
      }
    });
  });

  group('Future Flexibility: Metadata-driven filtering', () {
    test('Filtering by frequency ranking', () {
      final repository = KanjiRepository(initialData: testData);
      final top50Only = repository.filter(
        const KanjiFilterCriteria(maxFrequencyRank: 50),
      );
      expect(top50Only, isNotEmpty);
      for (final k in top50Only) {
        expect(k.metadata.frequencyRank, lessThanOrEqualTo(50));
      }
    });

    test('Filtering by commonness', () {
      final repository = KanjiRepository(initialData: testData);
      final veryCommon = repository.filter(
        const KanjiFilterCriteria(commonness: 'very_common'),
      );
      expect(veryCommon, isNotEmpty);
      for (final k in veryCommon) {
        expect(k.metadata.commonness, equals('very_common'));
      }
    });
  });

  group('AppState: Level switching preserves learning history', () {
    test('Changing level does not delete user learning history', () async {
      final storage = StorageService();
      final repository = KanjiRepository(initialData: testData);
      final selector = KanjiSelectorService(repository: repository);
      final notifications = NotificationService(selectorService: selector);

      final state = AppState(
        storageService: storage,
        kanjiRepository: repository,
        selectorService: selector,
        notificationService: notifications,
      );

      // Onboarding complete with N5
      await state.completeOnboarding(JLPTLevel.n5);
      expect(state.currentLevel, equals(JLPTLevel.n5));
      expect(state.isOnboardingCompleted, isTrue);

      // Record a learning interaction
      await state.recordReview('k_n5_001', isCorrect: true);
      expect(state.learningHistory.containsKey('k_n5_001'), isTrue);
      expect(state.learningHistory['k_n5_001']!.timesCorrect, equals(1));

      // Switch level to N4
      await state.updateLevel(JLPTLevel.n4);
      expect(state.currentLevel, equals(JLPTLevel.n4));

      // Notification pool immediately reflects N4 cumulative range
      expect(
        state.currentEligiblePool.any((k) => k.metadata.jlpt == JLPTLevel.n4),
        isTrue,
      );

      // Verification: History is completely preserved!
      expect(state.learningHistory.containsKey('k_n5_001'), isTrue);
      expect(state.learningHistory['k_n5_001']!.timesCorrect, equals(1));
    });

    test('DailyActivity serialization and StorageService persistence', () async {
      final storage = StorageService();
      const record = DailyActivity(
        date: '2026-10-06',
        glances: 15,
        uniqueKanji: 10,
        estimatedSeconds: 60,
        kanjiIds: ['k_n5_001', 'k_n5_002'],
      );

      await storage.saveDailyActivity(record);
      final loaded = await storage.loadDailyActivities();
      expect(loaded.containsKey('2026-10-06'), isTrue);
      expect(loaded['2026-10-06']!.glances, equals(15));
      expect(loaded['2026-10-06']!.uniqueKanji, equals(10));
      expect(loaded['2026-10-06']!.estimatedSeconds, equals(60));
      expect(loaded['2026-10-06']!.kanjiIds, equals(['k_n5_001', 'k_n5_002']));
    });
  });
}
