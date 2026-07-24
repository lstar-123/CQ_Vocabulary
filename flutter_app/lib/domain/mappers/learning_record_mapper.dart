import '../../models/group_memory.dart' as dto;
import '../models/learning_record.dart' as domain;

abstract final class LearningRecordMapper {
  static domain.LearningRecord fromDto(dto.GroupMemoryRecord d) {
    return domain.LearningRecord(
      id: d.id,
      unitId: d.unitId,
      eventType: domain.LearningEventType.fromApi(d.eventType),
      roundIndex: d.roundIndex,
      groupIndex: d.groupIndex,
      groupSize: d.groupSize,
      durationSeconds: d.durationSeconds,
      errorCount: d.errorCount,
      errorWords: d.errorWords.map(_errorWord).toList(growable: false),
      finishedAt: d.finishedAt,
    );
  }

  static domain.ErrorWord _errorWord(dto.ErrorWord e) {
    return domain.ErrorWord(english: e.english, chinese: e.chinese);
  }

  static domain.LearningHistory fromFullDto(dto.GroupHistoryFull d) {
    return domain.LearningHistory(
      records: d.records.map(fromDto).toList(growable: false),
      unitMaxCompletedRound: d.unitMaxCompletedRound,
      unitComplete: d.unitComplete,
    );
  }

  /// Domain → request DTO (for POST /api/group-learning/history).
  static dto.GroupHistoryRequest toRequestDto({
    required int unitId,
    String? bookSchema,
    required domain.LearningEventType eventType,
    int roundIndex = 0,
    int? groupIndex,
    int? groupSize,
    int? durationSeconds,
    int errorCount = 0,
    List<domain.ErrorWord>? errorWords,
    String? finishedAt,
  }) {
    return dto.GroupHistoryRequest(
      unitId: unitId,
      bookSchema: bookSchema,
      eventType: eventType.apiValue,
      roundIndex: roundIndex,
      groupIndex: groupIndex,
      groupSize: groupSize,
      durationSeconds: durationSeconds,
      errorCount: errorCount,
      errorWords: errorWords
          ?.map((e) => dto.ErrorWord(english: e.english, chinese: e.chinese))
          .toList(growable: false),
      finishedAt: finishedAt,
    );
  }
}
