import 'jlpt_level.dart';

/// Flexible metadata container for a Kanji character.
/// Allows the selection algorithm to evolve (frequency ranking, commonness, grades)
/// without altering database schemas or notification code.
class KanjiMetadata {
  /// The assigned JLPT level.
  final JLPTLevel jlpt;

  /// Frequency rank based on newspaper or media corpus (e.g. 1 to 2500).
  /// Lower numbers indicate higher real-world frequency.
  final int? frequencyRank;

  /// Qualitative commonness bucket (e.g., 'very_common', 'common', 'uncommon', 'rare').
  final String? commonness;

  /// Japanese school grade level (1-6 for elementary, 7+ for secondary).
  final int? grade;

  /// Total stroke count.
  final int? strokeCount;

  /// Optional contextual tags (e.g., 'nature', 'actions', 'business').
  final List<String> tags;

  const KanjiMetadata({
    required this.jlpt,
    this.frequencyRank,
    this.commonness,
    this.grade,
    this.strokeCount,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'jlpt': jlpt.code,
    'frequencyRank': frequencyRank,
    'commonness': commonness,
    'grade': grade,
    'strokeCount': strokeCount,
    'tags': tags,
  };

  factory KanjiMetadata.fromJson(Map<String, dynamic> json) {
    return KanjiMetadata(
      jlpt: JLPTLevelExtension.fromCode(json['jlpt'] as String) ?? JLPTLevel.n5,
      frequencyRank: json['frequencyRank'] as int?,
      commonness: json['commonness'] as String?,
      grade: json['grade'] as int?,
      strokeCount: json['strokeCount'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
