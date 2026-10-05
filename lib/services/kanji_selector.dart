import 'dart:math';
import '../models/jlpt_level.dart';
import '../models/kanji.dart';
import 'kanji_repository.dart';

/// Selection service responsible for computing the eligible Kanji pool
/// based on the user's current JLPT level (cumulative progression)
/// and picking random candidates for notifications and reviews.
class KanjiSelectorService {
  final KanjiRepository _repository;
  final Random _random;

  KanjiSelectorService({
    required KanjiRepository repository,
    Random? random,
  })  : _repository = repository,
        _random = random ?? Random();

  /// Computes the eligible Kanji pool for a given JLPT level using cumulative progression:
  /// - N5 → N5
  /// - N4 → N5 + N4
  /// - N3 → N5 + N4 + N3
  /// - N2 → N5 + N4 + N3 + N2
  /// - N1 → N5 + N4 + N3 + N2 + N1
  List<Kanji> getEligiblePool(JLPTLevel level) {
    final criteria = KanjiFilterCriteria.fromCumulativeLevel(level);
    return _repository.filter(criteria);
  }

  /// Randomly selects a Kanji strictly from the user's eligible pool.
  /// Throws an [EmptyPoolException] if the pool has no kanji.
  Kanji? selectRandomKanjiForLevel(JLPTLevel level, {List<String>? excludeIds}) {
    final pool = getEligiblePool(level);
    if (pool.isEmpty) {
      return null;
    }

    List<Kanji> candidatePool = pool;
    if (excludeIds != null && excludeIds.isNotEmpty) {
      final filtered =
          pool.where((k) => !excludeIds.contains(k.id)).toList();
      if (filtered.isNotEmpty) {
        candidatePool = filtered;
      }
    }

    final index = _random.nextInt(candidatePool.length);
    return candidatePool[index];
  }
}
