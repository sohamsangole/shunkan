/// Supported Japanese Language Proficiency Test (JLPT) levels.
enum JLPTLevel {
  n5,
  n4,
  n3,
  n2,
  n1,
}

extension JLPTLevelExtension on JLPTLevel {
  /// Standard code identifier (e.g., 'N5', 'N4').
  String get code {
    switch (this) {
      case JLPTLevel.n5:
        return 'N5';
      case JLPTLevel.n4:
        return 'N4';
      case JLPTLevel.n3:
        return 'N3';
      case JLPTLevel.n2:
        return 'N2';
      case JLPTLevel.n1:
        return 'N1';
    }
  }

  /// Full descriptive label as requested in design spec.
  String get displayName {
    switch (this) {
      case JLPTLevel.n5:
        return 'N5 — Beginner';
      case JLPTLevel.n4:
        return 'N4 — Elementary';
      case JLPTLevel.n3:
        return 'N3 — Intermediate';
      case JLPTLevel.n2:
        return 'N2 — Upper Intermediate';
      case JLPTLevel.n1:
        return 'N1 — Advanced';
    }
  }

  /// Short sub-title (e.g., 'Beginner').
  String get rankTitle {
    switch (this) {
      case JLPTLevel.n5:
        return 'Beginner';
      case JLPTLevel.n4:
        return 'Elementary';
      case JLPTLevel.n3:
        return 'Intermediate';
      case JLPTLevel.n2:
        return 'Upper Intermediate';
      case JLPTLevel.n1:
        return 'Advanced';
    }
  }

  /// Japanese rank classification (e.g., '初級').
  String get japaneseRank {
    switch (this) {
      case JLPTLevel.n5:
        return '入門';
      case JLPTLevel.n4:
        return '初級';
      case JLPTLevel.n3:
        return '中級';
      case JLPTLevel.n2:
        return '上級';
      case JLPTLevel.n1:
        return '最上級';
    }
  }

  /// Formatted level display in Japanese (e.g., 'N4 — 初級').
  String get japaneseDisplayName => '$code — $japaneseRank';

  /// Level subtitle description (e.g., 'Elementary Kanji').
  String get levelSubTitle {
    switch (this) {
      case JLPTLevel.n5:
        return 'Beginner Kanji';
      case JLPTLevel.n4:
        return 'Elementary Kanji';
      case JLPTLevel.n3:
        return 'Intermediate Kanji';
      case JLPTLevel.n2:
        return 'Upper Intermediate Kanji';
      case JLPTLevel.n1:
        return 'Advanced Kanji';
    }
  }

  /// Cumulative progression: returns all levels included at or below this level.
  /// - N5 → N5
  /// - N4 → N5 + N4
  /// - N3 → N5 + N4 + N3
  /// - N2 → N5 + N4 + N3 + N2
  /// - N1 → N5 + N4 + N3 + N2 + N1
  List<JLPTLevel> get cumulativeLevels {
    switch (this) {
      case JLPTLevel.n5:
        return [JLPTLevel.n5];
      case JLPTLevel.n4:
        return [JLPTLevel.n5, JLPTLevel.n4];
      case JLPTLevel.n3:
        return [JLPTLevel.n5, JLPTLevel.n4, JLPTLevel.n3];
      case JLPTLevel.n2:
        return [JLPTLevel.n5, JLPTLevel.n4, JLPTLevel.n3, JLPTLevel.n2];
      case JLPTLevel.n1:
        return [
          JLPTLevel.n5,
          JLPTLevel.n4,
          JLPTLevel.n3,
          JLPTLevel.n2,
          JLPTLevel.n1,
        ];
    }
  }

  /// Formatted explanation of the cumulative coverage for UI feedback.
  String get cumulativeDescription {
    switch (this) {
      case JLPTLevel.n5:
        return 'Includes N5 Kanji';
      case JLPTLevel.n4:
        return 'Includes N5 and N4 Kanji';
      case JLPTLevel.n3:
        return 'Includes N5, N4, and N3 Kanji';
      case JLPTLevel.n2:
        return 'Includes N5, N4, N3, and N2 Kanji';
      case JLPTLevel.n1:
        return 'Includes all Kanji (N5 through N1)';
    }
  }

  /// Parse from string code (case-insensitive)
  static JLPTLevel? fromCode(String? code) {
    if (code == null) return null;
    final normalized = code.trim().toUpperCase();
    for (final level in JLPTLevel.values) {
      if (level.code == normalized) {
        return level;
      }
    }
    return null;
  }
}
