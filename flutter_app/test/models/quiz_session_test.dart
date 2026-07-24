import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/models/quiz_session.dart';

/// Contract tests for QuizSession DTOs.
void main() {
  group('QuizSessionBrief', () {
    test('fromJson parses history list item', () {
      final json = {
        'id': 42,
        'unit_ids': '1,2,3',
        'total_count': 15,
        'correct_count': 12,
        'score_pct': 80.0,
        'duration_seconds': 180,
        'book_schema': 'grade6_vol1',
        'completed_at': '2026-07-24T10:30:00',
      };

      final session = QuizSessionBrief.fromJson(json);

      expect(session.id, 42);
      expect(session.unitIds, '1,2,3');
      expect(session.totalCount, 15);
      expect(session.correctCount, 12);
      expect(session.scorePct, 80.0);
      expect(session.durationSeconds, 180);
      expect(session.completedAt, '2026-07-24T10:30:00');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 1,
        'unit_ids': '1',
        'total_count': 5,
        'correct_count': 5,
        'score_pct': 100.0,
        'duration_seconds': null,
        'book_schema': null,
        'completed_at': null,
      };

      final session = QuizSessionBrief.fromJson(json);

      expect(session.durationSeconds, isNull);
      expect(session.bookSchema, isNull);
      expect(session.completedAt, isNull);
    });
  });

  group('QuizSessionDetail', () {
    test('fromJson parses detail response with answers', () {
      final json = {
        'id': 42,
        'unit_ids': '1,2',
        'total_count': 2,
        'correct_count': 1,
        'score_pct': 50.0,
        'duration_seconds': 60,
        'book_schema': 'grade6_vol1',
        'completed_at': '2026-07-24T10:30:00',
        'answers': [
          {
            'word_id': 1,
            'chinese': '苹果',
            'english': 'apple',
            'user_answer': '苹果',
            'is_correct': true,
          },
          {
            'word_id': 2,
            'chinese': '书',
            'english': 'book',
            'user_answer': 'pen',
            'is_correct': false,
          },
        ],
      };

      final detail = QuizSessionDetail.fromJson(json);

      expect(detail.id, 42);
      expect(detail.answers.length, 2);
      expect(detail.answers[0].wordId, 1);
      expect(detail.answers[0].isCorrect, isTrue);
      expect(detail.answers[1].userAnswer, 'pen');
    });

    test('fromJson handles empty answers list', () {
      final json = {
        'id': 1,
        'unit_ids': '',
        'total_count': 0,
        'correct_count': 0,
        'score_pct': 0,
        'answers': [],
      };

      final detail = QuizSessionDetail.fromJson(json);
      expect(detail.answers, isEmpty);
    });
  });

  group('QuizSubmitRequest', () {
    test('toJson produces backend-expected format', () {
      const request = QuizSubmitRequest(
        unitIds: [1, 2],
        answers: [
          AnswerSubmit(wordId: 1, userAnswer: '苹果', isCorrect: true),
          AnswerSubmit(wordId: 2, userAnswer: '书', isCorrect: true),
        ],
        durationSeconds: 120,
        bookSchema: 'grade6_vol1',
      );

      final json = request.toJson();

      expect(json['unit_ids'], [1, 2]);
      expect(json['answers'].length, 2);
      expect(json['answers'][0]['word_id'], 1);
      expect(json['duration_seconds'], 120);
      expect(json['book_schema'], 'grade6_vol1');
    });

    test('toJson omits optional fields when null', () {
      const request = QuizSubmitRequest(
        unitIds: [1],
        answers: [AnswerSubmit(wordId: 1, userAnswer: 'test', isCorrect: true)],
      );

      final json = request.toJson();

      expect(json.containsKey('duration_seconds'), isFalse);
      expect(json.containsKey('book_schema'), isFalse);
    });
  });

  group('QuizSubmitResponse', () {
    test('fromJson parses submit result', () {
      final json = {
        'session_id': 99,
        'total_count': 10,
        'correct_count': 8,
        'score_pct': 80.0,
      };

      final result = QuizSubmitResponse.fromJson(json);

      expect(result.sessionId, 99);
      expect(result.totalCount, 10);
      expect(result.correctCount, 8);
      expect(result.scorePct, 80.0);
    });
  });
}
