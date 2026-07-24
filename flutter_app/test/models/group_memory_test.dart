import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/models/group_memory.dart';

/// Contract tests for GroupMemory DTOs.
void main() {
  group('GroupMemoryRecord', () {
    test('fromJson parses group_complete record', () {
      final json = {
        'id': 1,
        'unit_id': 1,
        'event_type': 'group_complete',
        'round_index': 0,
        'group_index': 2,
        'group_size': 5,
        'duration_seconds': 60,
        'error_count': 1,
        'error_words': [
          {'english': 'apple', 'chinese': '苹果'},
        ],
        'finished_at': '2026-07-24T10:30:00',
      };

      final record = GroupMemoryRecord.fromJson(json);

      expect(record.id, 1);
      expect(record.eventType, 'group_complete');
      expect(record.errorCount, 1);
      expect(record.errorWords.length, 1);
      expect(record.errorWords[0].english, 'apple');
    });

    test('fromJson handles null optional fields in unit_complete', () {
      final json = {
        'id': 3,
        'unit_id': 1,
        'event_type': 'unit_complete',
        'round_index': 2,
        'group_index': null,
        'group_size': null,
        'duration_seconds': null,
        'error_count': 0,
        'error_words': [],
        'finished_at': null,
      };

      final record = GroupMemoryRecord.fromJson(json);

      expect(record.groupIndex, isNull);
      expect(record.groupSize, isNull);
      expect(record.durationSeconds, isNull);
      expect(record.errorWords, isEmpty);
    });
  });

  group('GroupHistoryRequest', () {
    test('toJson for group_complete includes group-specific fields', () {
      const request = GroupHistoryRequest(
        unitId: 1,
        eventType: 'group_complete',
        roundIndex: 0,
        groupIndex: 1,
        groupSize: 5,
        durationSeconds: 45,
        errorCount: 2,
        errorWords: [
          ErrorWord(english: 'test', chinese: '测试'),
        ],
      );

      final json = request.toJson();

      expect(json['unit_id'], 1);
      expect(json['event_type'], 'group_complete');
      expect(json['group_index'], 1);
      expect(json['group_size'], 5);
      expect(json['error_words'].length, 1);
    });

    test('toJson for unit_complete omits group-specific fields', () {
      const request = GroupHistoryRequest(
        unitId: 1,
        eventType: 'unit_complete',
        roundIndex: 2,
      );

      final json = request.toJson();

      expect(json.containsKey('group_index'), isFalse);
      expect(json.containsKey('group_size'), isFalse);
    });
  });

  group('GroupHistoryFull', () {
    test('fromJson parses the full history response envelope', () {
      final json = {
        'records': [
          {
            'id': 1,
            'unit_id': 1,
            'event_type': 'group_complete',
            'round_index': 0,
            'group_index': 0,
            'group_size': 5,
            'duration_seconds': 60,
            'error_count': 0,
            'error_words': [],
            'finished_at': '2026-07-24T10:30:00',
          },
        ],
        'unit_max_completed_round': {'1': 2, '2': 1},
        'unit_complete': [1],
      };

      final full = GroupHistoryFull.fromJson(json);

      expect(full.records.length, 1);
      expect(full.unitMaxCompletedRound[1], 2);
      expect(full.unitComplete, [1]);
    });
  });

  group('GroupHistoryResponse', () {
    test('fromJson parses POST /history response', () {
      final json = {
        'id': 42,
        'event_type': 'group_complete',
        'unit_id': 1,
        'round_index': 0,
      };

      final response = GroupHistoryResponse.fromJson(json);

      expect(response.id, 42);
      expect(response.eventType, 'group_complete');
      expect(response.unitId, 1);
    });
  });
}
