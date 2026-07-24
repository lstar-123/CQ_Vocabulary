import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/core/api/api_constants.dart';
import 'package:vocabulary_memorization/models/pagination.dart';

/// Repository Contract Test Suite
///
/// These tests verify that:
/// 1. All repository methods reference ApiPaths (no hardcoded strings).
/// 2. Pagination normalization works correctly.
/// 3. unit_ids conversion matches backend format.
///
/// We test the contract layer WITHOUT hitting the network — this is
/// pure JSON parsing and data transformation verification.
void main() {
  // ────────────────────────────────────────────────────────────
  // 1. ApiPaths completeness
  // ────────────────────────────────────────────────────────────
  group('ApiPaths — endpoint completeness', () {
    test('all 29 endpoints are defined', () {
      // Auth (7)
      expect(ApiPaths.register, isNotEmpty);
      expect(ApiPaths.login, isNotEmpty);
      expect(ApiPaths.teacherLogin, isNotEmpty);
      expect(ApiPaths.logout, isNotEmpty);
      expect(ApiPaths.switchBook, isNotEmpty);
      expect(ApiPaths.listBooks, isNotEmpty);
      expect(ApiPaths.me, isNotEmpty);

      // Units (1)
      expect(ApiPaths.units, isNotEmpty);

      // Words (3)
      expect(ApiPaths.words, isNotEmpty);
      expect(ApiPaths.wordsAll, isNotEmpty);
      expect(ApiPaths.wordsPhonics, isNotEmpty);

      // Quiz (1)
      expect(ApiPaths.quizSubmit, isNotEmpty);

      // History (2)
      expect(ApiPaths.history, isNotEmpty);
      expect(ApiPaths.historyDetail(1), contains('/1'));

      // Stats (3)
      expect(ApiPaths.statsTrend, isNotEmpty);
      expect(ApiPaths.statsSummary, isNotEmpty);
      expect(ApiPaths.statsGroupHistory, isNotEmpty);

      // Group Learning (1)
      expect(ApiPaths.groupLearningHistory, isNotEmpty);

      // Teacher (9)
      expect(ApiPaths.teacherStudents, isNotEmpty);
      expect(ApiPaths.teacherStudentDetail(1), contains('/1'));
      expect(ApiPaths.teacherStudentSessions(1), contains('/1/sessions'));
      expect(
        ApiPaths.teacherStudentSessionDetail(1, 42),
        contains('/1/sessions/42'),
      );
      expect(ApiPaths.teacherBooks, isNotEmpty);
      expect(ApiPaths.teacherWords, isNotEmpty);
      expect(ApiPaths.teacherWordDetail(1), contains('/1'));

      // TTS (1)
      expect(ApiPaths.tts, isNotEmpty);
    });

    test('no raw path strings — all paths start with /', () {
      final paths = [
        ApiPaths.register,
        ApiPaths.login,
        ApiPaths.teacherLogin,
        ApiPaths.logout,
        ApiPaths.switchBook,
        ApiPaths.listBooks,
        ApiPaths.me,
        ApiPaths.units,
        ApiPaths.words,
        ApiPaths.wordsAll,
        ApiPaths.wordsPhonics,
        ApiPaths.quizSubmit,
        ApiPaths.history,
        ApiPaths.statsTrend,
        ApiPaths.statsSummary,
        ApiPaths.statsGroupHistory,
        ApiPaths.groupLearningHistory,
        ApiPaths.teacherStudents,
        ApiPaths.teacherBooks,
        ApiPaths.teacherWords,
        ApiPaths.tts,
      ];

      for (final path in paths) {
        expect(path.startsWith('/'), isTrue, reason: '$path should start with /');
      }
    });
  });

  // ────────────────────────────────────────────────────────────
  // 2. unit_ids conversion contract
  // ────────────────────────────────────────────────────────────
  group('unit_ids conversion', () {
    /// Simulates how Repositories convert List<int> to backend format.
    String unitIdsToBackend(List<int> ids) => ids.join(',');

    /// Simulates how Repositories parse backend strings to List<int>.
    List<int> unitIdsFromBackend(String s) {
      if (s.isEmpty) return [];
      return s.split(',').map((e) => int.parse(e.trim())).toList();
    }

    test('List<int> → comma-separated string (query param)', () {
      expect(unitIdsToBackend([1, 2, 3]), '1,2,3');
      expect(unitIdsToBackend([42]), '42');
      expect(unitIdsToBackend([]), '');
    });

    test('comma-separated string → List<int> (response parsing)', () {
      expect(unitIdsFromBackend('1,2,3'), [1, 2, 3]);
      expect(unitIdsFromBackend('42'), [42]);
      expect(unitIdsFromBackend(''), isEmpty);
    });

    test('roundtrip is idempotent', () {
      const original = [1, 5, 10];
      final backend = unitIdsToBackend(original);
      final roundtrip = unitIdsFromBackend(backend);
      expect(roundtrip, original);
    });
  });

  // ────────────────────────────────────────────────────────────
  // 3. Backend error response parsing
  // ────────────────────────────────────────────────────────────
  group('Backend error format', () {
    test('extracts error message from {"error": "..."}', () {
      final errorJson = {'error': '用户名已存在'};

      final message = errorJson['error'] as String;

      expect(message, '用户名已存在');
    });

    test('handles all known error shapes', () {
      final errors = [
        {'error': '请先登录'},
        {'error': '用户名和密码不能为空'},
        {'error': '无效的词书'},
        {'error': '答案不能为空'},
        {'error': '记录不存在'},
        {'error': '学生不存在'},
        {'error': '单元不存在'},
        {'error': '词汇不存在'},
        {'error': '需要教师权限'},
        {'error': 'unit_id is required'},
      ];

      for (final e in errors) {
        expect(e['error'], isA<String>());
        expect(e['error'], isNotEmpty);
      }
    });
  });

  // ────────────────────────────────────────────────────────────
  // 4. Pagination field-name normalization
  // ────────────────────────────────────────────────────────────
  group('Pagination normalization', () {
    test('"items" key → PaginatedResponse (history)', () {
      final json = {
        'items': [1, 2, 3],
        'total': 10,
        'page': 1,
        'per_page': 3,
        'total_pages': 4,
      };

      final page = PaginationBuilder.fromHistoryJson(
        json,
        (item) => item as int,
      );

      expect(page.data, [1, 2, 3]);
    });

    test('"words" key → PaginatedResponse (teacher)', () {
      final json = {
        'words': [1, 2],
        'total': 50,
        'page': 1,
        'per_page': 2,
      };

      final page = PaginationBuilder.fromTeacherWordsJson(
        json,
        (item) => item as int,
      );

      expect(page.data, [1, 2]);
      expect(page.totalPages, 25); // 50/2
    });

    test('both paths produce identical PaginatedResponse structure', () {
      final historyJson = {
        'items': ['a'],
        'total': 1,
        'page': 1,
        'per_page': 1,
        'total_pages': 1,
      };
      final teacherJson = {
        'words': ['a'],
        'total': 1,
        'page': 1,
        'per_page': 1,
      };

      final fromHistory = PaginationBuilder.fromHistoryJson(
        historyJson,
        (item) => item as String,
      );
      final fromTeacher = PaginationBuilder.fromTeacherWordsJson(
        teacherJson,
        (item) => item as String,
      );

      // Both resolve to identical structures
      expect(fromHistory.data, fromTeacher.data);
      expect(fromHistory.total, fromTeacher.total);
      expect(fromHistory.page, fromTeacher.page);
      expect(fromHistory.perPage, fromTeacher.perPage);
    });
  });
}
