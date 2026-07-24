/// Unit DTOs — mapped from GET /api/units and GET /api/words/all.
library;

import 'word.dart';

/// Returned by GET /api/units.
class UnitBrief {
  const UnitBrief({
    required this.id,
    required this.name,
    required this.wordCount,
  });

  final int id;
  final String name;
  final int wordCount;

  factory UnitBrief.fromJson(Map<String, dynamic> json) {
    return UnitBrief(
      id: json['id'] as int,
      name: json['name'] as String,
      wordCount: json['word_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'word_count': wordCount,
    };
  }
}

/// Returned by GET /api/words/all — a unit with its word list.
class UnitWithWords {
  const UnitWithWords({
    required this.unitId,
    required this.unitName,
    required this.orderNum,
    required this.words,
  });

  final int unitId;
  final String unitName;
  final int orderNum;
  final List<WordBrief> words;

  factory UnitWithWords.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'] as List<dynamic>? ?? [];
    return UnitWithWords(
      unitId: json['unit_id'] as int,
      unitName: json['unit_name'] as String,
      orderNum: json['order_num'] as int,
      words: rawWords
          .map((w) => WordBrief.fromJson(w as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
