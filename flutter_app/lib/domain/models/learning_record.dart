/// Domain models for group-based memorization history.
enum LearningEventType {
  groupComplete,
  roundComplete,
  unitComplete;

  String get apiValue {
    return switch (this) {
      LearningEventType.groupComplete => 'group_complete',
      LearningEventType.roundComplete => 'round_complete',
      LearningEventType.unitComplete => 'unit_complete',
    };
  }

  static LearningEventType fromApi(String value) {
    return switch (value) {
      'group_complete' => LearningEventType.groupComplete,
      'round_complete' => LearningEventType.roundComplete,
      'unit_complete' => LearningEventType.unitComplete,
      _ => throw ArgumentError('Unknown event_type: $value'),
    };
  }
}

/// A single immutable history record.
class LearningRecord {
  const LearningRecord({
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
  final LearningEventType eventType;
  final int roundIndex;
  final int? groupIndex;
  final int? groupSize;
  final int? durationSeconds;
  final int errorCount;
  final List<ErrorWord> errorWords;
  final String? finishedAt;
}

class ErrorWord {
  const ErrorWord({
    required this.english,
    required this.chinese,
  });

  final String english;
  final String chinese;
}

/// Full history response with computed summaries.
class LearningHistory {
  const LearningHistory({
    required this.records,
    required this.unitMaxCompletedRound,
    required this.unitComplete,
  });

  final List<LearningRecord> records;
  final Map<int, int> unitMaxCompletedRound;
  final List<int> unitComplete;
}
