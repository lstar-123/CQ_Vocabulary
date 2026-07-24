/// Group-memory-history DTOs.
///
/// Backend sources:
///   POST /api/group-learning/history → GroupHistoryResponse
///   GET  /api/group-learning/history  → GroupHistoryFull
///   GET  /api/stats/group-history     → List<GroupMemoryRecord>
library;

/// A single immutable history record.
class GroupMemoryRecord {
  const GroupMemoryRecord({
    required this.id,
    required this.unitId,
    required this.eventType,
    required this.roundIndex,
    this.groupIndex,
    this.groupSize,
    this.durationSeconds,
    required this.errorCount,
    required this.errorWords,
    this.finishedAt,
  });

  final int id;
  final int unitId;
  final String eventType; // "group_complete" | "round_complete" | "unit_complete"
  final int roundIndex;
  final int? groupIndex;
  final int? groupSize;
  final int? durationSeconds;
  final int errorCount;
  final List<ErrorWord> errorWords;
  final String? finishedAt; // ISO 8601

  factory GroupMemoryRecord.fromJson(Map<String, dynamic> json) {
    final rawErrors = json['error_words'] as List<dynamic>? ?? [];
    return GroupMemoryRecord(
      id: json['id'] as int,
      unitId: json['unit_id'] as int,
      eventType: json['event_type'] as String,
      roundIndex: json['round_index'] as int,
      groupIndex: json['group_index'] as int?,
      groupSize: json['group_size'] as int?,
      durationSeconds: json['duration_seconds'] as int?,
      errorCount: json['error_count'] as int? ?? 0,
      errorWords: rawErrors
          .map((e) => ErrorWord.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      finishedAt: json['finished_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit_id': unitId,
      'event_type': eventType,
      'round_index': roundIndex,
      'group_index': groupIndex,
      'group_size': groupSize,
      'duration_seconds': durationSeconds,
      'error_count': errorCount,
      'error_words': errorWords.map((e) => e.toJson()).toList(),
      'finished_at': finishedAt,
    };
  }
}

/// A word that the learner got wrong.
class ErrorWord {
  const ErrorWord({
    required this.english,
    required this.chinese,
  });

  final String english;
  final String chinese;

  factory ErrorWord.fromJson(Map<String, dynamic> json) {
    return ErrorWord(
      english: json['english'] as String,
      chinese: json['chinese'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'english': english,
      'chinese': chinese,
    };
  }
}

// ── Request / Response ───────────────────────────────────────

/// Request body for POST /api/group-learning/history.
class GroupHistoryRequest {
  const GroupHistoryRequest({
    required this.unitId,
    this.bookSchema,
    required this.eventType,
    this.roundIndex = 0,
    this.groupIndex,
    this.groupSize,
    this.durationSeconds,
    this.errorCount = 0,
    this.errorWords,
    this.finishedAt,
  });

  final int unitId;
  final String? bookSchema;
  final String eventType;
  final int roundIndex;
  final int? groupIndex;
  final int? groupSize;
  final int? durationSeconds;
  final int errorCount;
  final List<ErrorWord>? errorWords;
  final String? finishedAt;

  Map<String, dynamic> toJson() {
    return {
      'unit_id': unitId,
      if (bookSchema != null) 'book_schema': bookSchema,
      'event_type': eventType,
      'round_index': roundIndex,
      if (groupIndex != null) 'group_index': groupIndex,
      if (groupSize != null) 'group_size': groupSize,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      'error_count': errorCount,
      if (errorWords != null)
        'error_words': errorWords!.map((e) => e.toJson()).toList(),
      if (finishedAt != null) 'finished_at': finishedAt,
    };
  }
}

/// Response from POST /api/group-learning/history.
class GroupHistoryResponse {
  const GroupHistoryResponse({
    required this.id,
    required this.eventType,
    required this.unitId,
    required this.roundIndex,
  });

  final int id;
  final String eventType;
  final int unitId;
  final int roundIndex;

  factory GroupHistoryResponse.fromJson(Map<String, dynamic> json) {
    return GroupHistoryResponse(
      id: json['id'] as int,
      eventType: json['event_type'] as String,
      unitId: json['unit_id'] as int,
      roundIndex: json['round_index'] as int,
    );
  }
}

/// Response from GET /api/group-learning/history.
class GroupHistoryFull {
  const GroupHistoryFull({
    required this.records,
    required this.unitMaxCompletedRound,
    required this.unitComplete,
  });

  final List<GroupMemoryRecord> records;
  final Map<int, int> unitMaxCompletedRound;
  final List<int> unitComplete;

  factory GroupHistoryFull.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'] as List<dynamic>? ?? [];
    final rawRoundMap =
        json['unit_max_completed_round'] as Map<String, dynamic>? ?? {};
    final rawComplete = json['unit_complete'] as List<dynamic>? ?? [];

    return GroupHistoryFull(
      records: rawRecords
          .map((r) => GroupMemoryRecord.fromJson(r as Map<String, dynamic>))
          .toList(growable: false),
      unitMaxCompletedRound: rawRoundMap.map(
        (k, v) => MapEntry(int.parse(k), v as int),
      ),
      unitComplete:
          rawComplete.map((e) => e as int).toList(growable: false),
    );
  }
}
