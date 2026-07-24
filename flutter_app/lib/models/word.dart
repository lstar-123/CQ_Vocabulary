/// Word DTOs — mapped from GET /api/words, /api/words/all,
/// and teacher word management endpoints.
library;

/// Basic word representation used in lists.
class WordBrief {
  const WordBrief({
    required this.id,
    required this.unitId,
    required this.unitName,
    required this.english,
    required this.chinese,
  });

  final int id;
  final int unitId;
  final String unitName;
  final String english;
  final String chinese;

  factory WordBrief.fromJson(Map<String, dynamic> json) {
    return WordBrief(
      id: json['id'] as int,
      unitId: json['unit_id'] as int,
      unitName: (json['unit_name'] as String?) ?? '',
      english: json['english'] as String,
      chinese: json['chinese'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit_id': unitId,
      'unit_name': unitName,
      'english': english,
      'chinese': chinese,
    };
  }
}

/// Minimal word reference used in nested contexts (e.g., UnitWithWords).
class WordBriefInline {
  const WordBriefInline({
    required this.id,
    required this.english,
    required this.chinese,
  });

  final int id;
  final String english;
  final String chinese;

  factory WordBriefInline.fromJson(Map<String, dynamic> json) {
    return WordBriefInline(
      id: json['id'] as int,
      english: json['english'] as String,
      chinese: json['chinese'] as String,
    );
  }
}

/// Request body for teacher word creation (POST /api/teacher/words).
class CreateWordRequest {
  const CreateWordRequest({
    required this.unitId,
    required this.english,
    required this.chinese,
    this.bookSchema,
  });

  final int unitId;
  final String english;
  final String chinese;
  final String? bookSchema;

  Map<String, dynamic> toJson() {
    return {
      'unit_id': unitId,
      'english': english,
      'chinese': chinese,
      if (bookSchema != null) 'book_schema': bookSchema,
    };
  }
}

/// Request body for teacher word update (PUT /api/teacher/words/<id>).
class UpdateWordRequest {
  const UpdateWordRequest({
    this.unitId,
    this.english,
    this.chinese,
    this.bookSchema,
  });

  final int? unitId;
  final String? english;
  final String? chinese;
  final String? bookSchema;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (unitId != null) map['unit_id'] = unitId;
    if (english != null) map['english'] = english;
    if (chinese != null) map['chinese'] = chinese;
    if (bookSchema != null) map['book_schema'] = bookSchema;
    return map;
  }
}
