import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/domain/mappers/book_mapper.dart';
import 'package:vocabulary_memorization/domain/mappers/pagination_mapper.dart';
import 'package:vocabulary_memorization/domain/mappers/quiz_mapper.dart';
import 'package:vocabulary_memorization/domain/mappers/statistics_mapper.dart';
import 'package:vocabulary_memorization/domain/mappers/user_mapper.dart';
import 'package:vocabulary_memorization/domain/models/pagination.dart' as domain;
import 'package:vocabulary_memorization/domain/models/quiz.dart' as domain;
import 'package:vocabulary_memorization/domain/models/statistics.dart' as domain;
import 'package:vocabulary_memorization/domain/models/user.dart' as domain;
import 'package:vocabulary_memorization/models/book.dart' as dto;
import 'package:vocabulary_memorization/models/pagination.dart' as dto;
import 'package:vocabulary_memorization/models/quiz_session.dart' as dto;
import 'package:vocabulary_memorization/models/statistics.dart' as dto;
import 'package:vocabulary_memorization/models/user.dart' as dto;

/// Contract tests verifying DTO → Domain Model mapping correctness.
///
/// These tests ensure that:
/// 1. Every DTO field is correctly transferred to its domain counterpart.
/// 2. [unitIds] String→List<int> conversion is lossless.
/// 3. [UserRole] enum mapping is correct.
/// 4. Pagination normalization produces domain [PaginatedResult].
/// 5. Optional/nullable fields are handled without crashes.
void main() {
  // ────────────────────────────────────────────────────────────
  // User Mapping
  // ────────────────────────────────────────────────────────────
  group('UserMapper — DTO → Domain', () {
    test('UserBrief → User preserves all fields', () {
      const dtoUser = dto.UserBrief(
        id: 7,
        username: 'alice',
        role: 'student',
        currentBook: 'grade6_vol1',
      );

      final user = UserMapper.fromBriefDto(dtoUser);

      expect(user.id, 7);
      expect(user.username, 'alice');
      expect(user.role, domain.UserRole.student);
      expect(user.currentBook, 'grade6_vol1');
      expect(user.isStudent, isTrue);
      expect(user.isTeacher, isFalse);
    });

    test('TeacherBrief → User maps role correctly', () {
      const dtoTeacher = dto.TeacherBrief(id: 1, username: 'admin');

      final user = UserMapper.fromTeacherDto(dtoTeacher);

      expect(user.role, domain.UserRole.teacher);
      expect(user.isTeacher, isTrue);
      expect(user.currentBook, isNull);
    });

    test('StudentInfo → StudentSummary', () {
      const dtoStudent = dto.StudentInfo(
        id: 3,
        username: 'bob',
        createdAt: '2026-07-01T10:00:00',
        totalQuizzes: 15,
        avgScore: 88.5,
        bestScore: 100.0,
        totalWordsTested: 150,
      );

      final summary = UserMapper.fromStudentInfoDto(dtoStudent);

      expect(summary.id, 3);
      expect(summary.totalQuizzes, 15);
      expect(summary.avgScore, 88.5);
      expect(summary.totalWordsTested, 150);
    });
  });

  // ────────────────────────────────────────────────────────────
  // Quiz Mapping (critical: unitIds conversion)
  // ────────────────────────────────────────────────────────────
  group('QuizMapper — unitIds String→List<int>', () {
    test('QuizSessionBrief → QuizSession with comma-separated unitIds', () {
      const dtoSession = dto.QuizSessionBrief(
        id: 42,
        unitIds: '1,2,3',
        totalCount: 15,
        correctCount: 12,
        scorePct: 80.0,
        durationSeconds: 180,
        bookSchema: 'grade6_vol1',
        completedAt: '2026-07-24T10:30:00',
      );

      final session = QuizMapper.fromBriefDto(dtoSession);

      expect(session.unitIds, [1, 2, 3]);
      expect(session.totalCount, 15);
      expect(session.scorePct, 80.0);
    });

    test('QuizSessionDetail → domain with answers', () {
      const dtoDetail = dto.QuizSessionDetail(
        id: 1,
        unitIds: '1',
        totalCount: 2,
        correctCount: 1,
        scorePct: 50.0,
        answers: [
          dto.QuizAnswerItem(
            wordId: 1,
            chinese: '苹果',
            english: 'apple',
            userAnswer: '苹果',
            isCorrect: true,
          ),
        ],
      );

      final detail = QuizMapper.fromDetailDto(dtoDetail);

      expect(detail.unitIds, [1]);
      expect(detail.answers.length, 1);
      expect(detail.answers.first.isCorrect, isTrue);
    });

    test('single unit_id string → singleton list', () {
      const dtoSession = dto.QuizSessionBrief(
        id: 1,
        unitIds: '42',
        totalCount: 5,
        correctCount: 5,
        scorePct: 100.0,
      );

      final session = QuizMapper.fromBriefDto(dtoSession);

      expect(session.unitIds, [42]);
    });

    test('empty unit_ids string → empty list', () {
      const dtoSession = dto.QuizSessionBrief(
        id: 1,
        unitIds: '',
        totalCount: 0,
        correctCount: 0,
        scorePct: 0,
      );

      final session = QuizMapper.fromBriefDto(dtoSession);

      expect(session.unitIds, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────
  // Statistics Mapping
  // ────────────────────────────────────────────────────────────
  group('StatisticsMapper — unitIds + unit_scores key conversion', () {
    test('TrendPoint → ScoreTrend with per-unit scores', () {
      const dtoPoint = dto.TrendPoint(
        date: '07-24 10:30',
        scorePct: 85.0,
        totalCount: 10,
        correctCount: 8,
        unitIds: '1,2',
        unitNames: ['Unit 1', 'Unit 2'],
        unitScores: {
          '1': dto.UnitScore(total: 5, correct: 4, scorePct: 80.0),
          '2': dto.UnitScore(total: 5, correct: 4, scorePct: 80.0),
        },
      );

      final trend = StatisticsMapper.fromTrendPointDto(dtoPoint);

      expect(trend.unitIds, [1, 2]);
      expect(trend.unitScores!.keys, contains(1));
      expect(trend.unitScores![1]!.total, 5);
    });

    test('TrendPoint without unit_scores (nullable)', () {
      const dtoPoint = dto.TrendPoint(
        date: '07-24',
        scorePct: 90.0,
        totalCount: 5,
        correctCount: 4,
        unitIds: '1',
        unitNames: ['Unit 1'],
      );

      final trend = StatisticsMapper.fromTrendPointDto(dtoPoint);

      expect(trend.unitIds, [1]);
      expect(trend.unitScores, isNull);
    });
  });

  // ────────────────────────────────────────────────────────────
  // Pagination Mapping
  // ────────────────────────────────────────────────────────────
  group('PaginationMapper — DTO → Domain', () {
    test('maps PaginatedResponse<DTO> → PaginatedResult<Domain>', () {
      const dtoPage = dto.PaginatedResponse<String>(
        data: ['a', 'b', 'c'],
        total: 10,
        page: 1,
        perPage: 3,
        totalPages: 4,
      );

      final result = PaginationMapper.fromDto(
        dtoPage,
        (s) => 'domain-$s',
      );

      expect(result, isA<domain.PaginatedResult<String>>());
      expect(result.items, ['domain-a', 'domain-b', 'domain-c']);
      expect(result.total, 10);
      expect(result.page, 1);
      expect(result.hasMore, isTrue);
    });

    test('preserves all pagination metadata', () {
      const dtoPage = dto.PaginatedResponse<int>(
        data: [],
        total: 0,
        page: 1,
        perPage: 20,
        totalPages: 1,
      );

      final result = PaginationMapper.fromDto(dtoPage, (i) => i.toString());

      expect(result.total, 0);
      expect(result.hasMore, isFalse);
      expect(result.isEmpty, isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────
  // Book Mapping
  // ────────────────────────────────────────────────────────────
  group('BookMapper', () {
    test('BookInfo → Book', () {
      const dtoBook = dto.BookInfo(schema: 'senior_compulsory_1', name: '高中必修一');

      final book = BookMapper.fromDto(dtoBook);

      expect(book.schema, 'senior_compulsory_1');
      expect(book.name, '高中必修一');
    });
  });
}
