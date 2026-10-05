import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/jlpt_level.dart';
import '../models/kanji.dart';

/// Extensible criteria for querying Kanji.
/// Can be extended in the future without breaking notification or database layers.
class KanjiFilterCriteria {
  final List<JLPTLevel>? jlptLevels;
  final int? maxFrequencyRank;
  final String? commonness;
  final int? maxStrokeCount;
  final List<String>? tags;

  const KanjiFilterCriteria({
    this.jlptLevels,
    this.maxFrequencyRank,
    this.commonness,
    this.maxStrokeCount,
    this.tags,
  });

  /// Factory helper for cumulative JLPT filtering
  factory KanjiFilterCriteria.fromCumulativeLevel(JLPTLevel level) {
    return KanjiFilterCriteria(
      jlptLevels: level.cumulativeLevels,
    );
  }
}

/// Central repository providing access to Kanji entries and filtering.
class KanjiRepository {
  final List<Kanji> _allKanji;

  KanjiRepository({List<Kanji>? initialData})
      : _allKanji = initialData ?? const [];

  /// Automatically loads assets/data/kanji.json if present.
  static Future<KanjiRepository> create() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/kanji.json');
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        final list = decoded
            .map((item) => Kanji.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          return KanjiRepository(initialData: list);
        }
      }
    } catch (_) {}
    return KanjiRepository(initialData: const []);
  }

  List<Kanji> getAll() => List.unmodifiable(_allKanji);

  /// Filters Kanji based on extensible metadata criteria.
  List<Kanji> filter(KanjiFilterCriteria criteria) {
    return _allKanji.where((kanji) {
      final meta = kanji.metadata;

      // Filter by JLPT levels (e.g. cumulative N5..N2)
      if (criteria.jlptLevels != null &&
          !criteria.jlptLevels!.contains(meta.jlpt)) {
        return false;
      }

      // Filter by frequency rank
      if (criteria.maxFrequencyRank != null) {
        if (meta.frequencyRank == null ||
            meta.frequencyRank! > criteria.maxFrequencyRank!) {
          return false;
        }
      }

      // Filter by commonness
      if (criteria.commonness != null &&
          meta.commonness != criteria.commonness) {
        return false;
      }

      // Filter by stroke count
      if (criteria.maxStrokeCount != null) {
        if (meta.strokeCount == null ||
            meta.strokeCount! > criteria.maxStrokeCount!) {
          return false;
        }
      }

      // Filter by tags
      if (criteria.tags != null && criteria.tags!.isNotEmpty) {
        final hasAnyTag = criteria.tags!.any((t) => meta.tags.contains(t));
        if (!hasAnyTag) return false;
      }

      return true;
    }).toList();
  }

  Kanji? getById(String id) {
    try {
      return _allKanji.firstWhere((k) => k.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns count of Kanji grouped by each JLPT level.
  Map<JLPTLevel, int> getCountsByLevel() {
    final Map<JLPTLevel, int> map = {
      for (final lvl in JLPTLevel.values) lvl: 0,
    };
    for (final k in _allKanji) {
      map[k.metadata.jlpt] = (map[k.metadata.jlpt] ?? 0) + 1;
    }
    return map;
  }
}
