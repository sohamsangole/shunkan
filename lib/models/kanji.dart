import 'kanji_metadata.dart';

/// Converts a Katakana string to Hiragana using standard Unicode offset (0x60).
String katakanaToHiragana(String text) {
  return text.split('').map((char) {
    if (char.isEmpty) return char;
    final code = char.codeUnitAt(0);
    // Katakana Unicode range: 0x30A1 (ァ) to 0x30F6 (ヶ)
    if (code >= 0x30A1 && code <= 0x30F6) {
      return String.fromCharCode(code - 0x60);
    }
    return char;
  }).join('');
}

/// Real-world compound vocabulary example for a Kanji.
class KanjiExample {
  final String word; // e.g. '心配'
  final String reading; // e.g. 'しんぱい' in Hiragana
  final String meaning; // e.g. 'worry'
  final bool isOnyomi; // true for On reading, false for Kun reading

  const KanjiExample({
    required this.word,
    required this.reading,
    required this.meaning,
    this.isOnyomi = true,
  });

  Map<String, dynamic> toJson() => {
    'word': word,
    'reading': reading,
    'meaning': meaning,
    'isOnyomi': isOnyomi,
  };

  factory KanjiExample.fromJson(Map<String, dynamic> json) => KanjiExample(
    word: json['word'] as String,
    reading: json['reading'] as String,
    meaning: json['meaning'] as String,
    isOnyomi: json['isOnyomi'] as bool? ?? true,
  );
}

/// Represents a single Kanji character entry with readings and metadata.
class Kanji {
  final String id;
  final String character;
  final List<String> meanings;
  final List<String> onyomi;
  final List<String> kunyomi;
  final List<KanjiExample> examples;
  final KanjiMetadata metadata;

  const Kanji({
    required this.id,
    required this.character,
    required this.meanings,
    required this.onyomi,
    required this.kunyomi,
    this.examples = const [],
    required this.metadata,
  });

  String get primaryMeaning => meanings.isNotEmpty ? meanings.first : '';
  String get meaningsDisplay => meanings.join(', ');

  /// All Onyomi converted to Hiragana (no Katakana shown)
  List<String> get onyomiHiragana =>
      onyomi.map(katakanaToHiragana).toList();

  String get onyomiHiraganaDisplay =>
      onyomiHiragana.isNotEmpty ? onyomiHiragana.join('・') : '-';

  String get onyomiDisplay => onyomiHiraganaDisplay;

  String get kunyomiDisplay =>
      kunyomi.isNotEmpty ? kunyomi.join('・') : '-';

  List<KanjiExample> get onExamples =>
      examples.where((e) => e.isOnyomi).toList();

  List<KanjiExample> get kunExamples =>
      examples.where((e) => !e.isOnyomi).toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'character': character,
    'meanings': meanings,
    'onyomi': onyomi,
    'kunyomi': kunyomi,
    'examples': examples.map((e) => e.toJson()).toList(),
    'metadata': metadata.toJson(),
  };

  factory Kanji.fromJson(Map<String, dynamic> json) {
    return Kanji(
      id: json['id'] as String,
      character: json['character'] as String,
      meanings:
          (json['meanings'] as List<dynamic>).map((e) => e.toString()).toList(),
      onyomi:
          (json['onyomi'] as List<dynamic>).map((e) => e.toString()).toList(),
      kunyomi:
          (json['kunyomi'] as List<dynamic>).map((e) => e.toString()).toList(),
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => KanjiExample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata:
          KanjiMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }
}
