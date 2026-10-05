/// Tracks user learning progress for a specific Kanji.
/// Stored independently from UserSettings so changing JLPT levels never alters or wipes progress.
class LearningRecord {
  final String kanjiId;
  final int timesSeen;
  final int timesTested;
  final int timesCorrect;
  final DateTime lastSeenAt;
  final bool isBookmarked;
  final double masteryScore; // 0.0 to 1.0

  const LearningRecord({
    required this.kanjiId,
    this.timesSeen = 0,
    this.timesTested = 0,
    this.timesCorrect = 0,
    required this.lastSeenAt,
    this.isBookmarked = false,
    this.masteryScore = 0.0,
  });

  LearningRecord copyWith({
    int? timesSeen,
    int? timesTested,
    int? timesCorrect,
    DateTime? lastSeenAt,
    bool? isBookmarked,
    double? masteryScore,
  }) {
    return LearningRecord(
      kanjiId: kanjiId,
      timesSeen: timesSeen ?? this.timesSeen,
      timesTested: timesTested ?? this.timesTested,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      masteryScore: masteryScore ?? this.masteryScore,
    );
  }

  Map<String, dynamic> toJson() => {
    'kanjiId': kanjiId,
    'timesSeen': timesSeen,
    'timesTested': timesTested,
    'timesCorrect': timesCorrect,
    'lastSeenAt': lastSeenAt.toIso8601String(),
    'isBookmarked': isBookmarked,
    'masteryScore': masteryScore,
  };

  factory LearningRecord.fromJson(Map<String, dynamic> json) {
    return LearningRecord(
      kanjiId: json['kanjiId'] as String,
      timesSeen: json['timesSeen'] as int? ?? 0,
      timesTested: json['timesTested'] as int? ?? 0,
      timesCorrect: json['timesCorrect'] as int? ?? 0,
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? '') ??
          DateTime.now(),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      masteryScore: (json['masteryScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
