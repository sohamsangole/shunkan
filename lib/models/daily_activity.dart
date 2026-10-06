/// Represents the aggregate passive and active Kanji exposure for a single calendar day.
class DailyActivity {
  final String date; // Format: 'yyyy-MM-dd'
  final int glances;
  final int uniqueKanji;
  final int estimatedSeconds;
  final List<String> kanjiIds;

  const DailyActivity({
    required this.date,
    required this.glances,
    required this.uniqueKanji,
    required this.estimatedSeconds,
    this.kanjiIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'glances': glances,
    'uniqueKanji': uniqueKanji,
    'estimatedSeconds': estimatedSeconds,
    'kanjiIds': kanjiIds,
  };

  factory DailyActivity.fromJson(Map<String, dynamic> json) => DailyActivity(
    date: json['date'] as String? ?? '',
    glances: (json['glances'] as num?)?.toInt() ?? 0,
    uniqueKanji: (json['uniqueKanji'] as num?)?.toInt() ?? 0,
    estimatedSeconds: (json['estimatedSeconds'] as num?)?.toInt() ?? 0,
    kanjiIds: (json['kanjiIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
  );

  DailyActivity copyWith({
    String? date,
    int? glances,
    int? uniqueKanji,
    int? estimatedSeconds,
    List<String>? kanjiIds,
  }) {
    return DailyActivity(
      date: date ?? this.date,
      glances: glances ?? this.glances,
      uniqueKanji: uniqueKanji ?? this.uniqueKanji,
      estimatedSeconds: estimatedSeconds ?? this.estimatedSeconds,
      kanjiIds: kanjiIds ?? this.kanjiIds,
    );
  }
}
