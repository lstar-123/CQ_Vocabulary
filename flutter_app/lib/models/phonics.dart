/// Phonics DTOs — mapped from GET /api/words/phonics.
///
/// Backend v2 schema: segments are nested inside syllables.
library;

class PhonicsData {
  const PhonicsData({
    required this.word,
    this.ipa,
    this.arpabet,
    required this.syllables,
  });

  final String word;
  final String? ipa;
  final String? arpabet;
  final List<PhonicsSyllable> syllables;

  factory PhonicsData.fromJson(Map<String, dynamic> json) {
    final rawSyllables = json['syllables'] as List<dynamic>? ?? [];
    return PhonicsData(
      word: json['word'] as String,
      ipa: json['ipa'] as String?,
      arpabet: json['arpabet'] as String?,
      syllables: rawSyllables
          .map((s) => PhonicsSyllable.fromJson(s as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'ipa': ipa,
      'arpabet': arpabet,
      'syllables': syllables.map((s) => s.toJson()).toList(),
    };
  }
}

class PhonicsSyllable {
  const PhonicsSyllable({
    required this.text,
    required this.stress,
    required this.segments,
  });

  final String text;
  final int stress;
  final List<PhonicsSegment> segments;

  factory PhonicsSyllable.fromJson(Map<String, dynamic> json) {
    final rawSegments = json['segments'] as List<dynamic>? ?? [];
    return PhonicsSyllable(
      text: json['text'] as String,
      stress: json['stress'] as int,
      segments: rawSegments
          .map((s) => PhonicsSegment.fromJson(s as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'stress': stress,
      'segments': segments.map((s) => s.toJson()).toList(),
    };
  }
}

class PhonicsSegment {
  const PhonicsSegment({
    required this.text,
    required this.silent,
    required this.rule,
  });

  final String text;
  final bool silent;
  final String rule;

  factory PhonicsSegment.fromJson(Map<String, dynamic> json) {
    return PhonicsSegment(
      text: json['text'] as String,
      silent: json['silent'] as bool,
      rule: json['rule'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'silent': silent,
      'rule': rule,
    };
  }
}
