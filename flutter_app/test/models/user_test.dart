import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/models/user.dart';

/// Contract tests for User DTOs.
///
/// Verifies JSON serialization matches backend response shapes
/// as documented in Milestone 0.
void main() {
  group('UserBrief', () {
    test('fromJson parses a student login response', () {
      final json = {
        'id': 1,
        'username': 'alice',
        'role': 'student',
        'current_book': 'grade6_vol1',
      };

      final user = UserBrief.fromJson(json);

      expect(user.id, 1);
      expect(user.username, 'alice');
      expect(user.role, 'student');
      expect(user.currentBook, 'grade6_vol1');
    });

    test('fromJson handles null current_book (new user)', () {
      final json = {
        'id': 2,
        'username': 'bob',
        'role': 'student',
        'current_book': null,
      };

      final user = UserBrief.fromJson(json);

      expect(user.currentBook, isNull);
    });

    test('toJson produces the backend-expected format', () {
      const user = UserBrief(
        id: 1,
        username: 'alice',
        role: 'student',
        currentBook: 'grade6_vol1',
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['username'], 'alice');
      expect(json['role'], 'student');
      expect(json['current_book'], 'grade6_vol1');
    });

    test('fromJson → toJson roundtrip is idempotent', () {
      final original = {
        'id': 1,
        'username': 'alice',
        'role': 'student',
        'current_book': 'grade6_vol1',
      };

      final result = UserBrief.fromJson(original).toJson();

      expect(result, original);
    });
  });

  group('TeacherBrief', () {
    test('fromJson parses teacher login response', () {
      final json = {
        'id': 1,
        'username': 'admin',
        'role': 'teacher',
      };

      final teacher = TeacherBrief.fromJson(json);

      expect(teacher.id, 1);
      expect(teacher.username, 'admin');
    });
  });

  group('StudentInfo', () {
    test('fromJson parses teacher student list response', () {
      final json = {
        'id': 1,
        'username': 'alice',
        'created_at': '2026-07-01T10:00:00',
        'total_quizzes': 25,
        'avg_score': 85.3,
        'best_score': 100.0,
        'total_words_tested': 250,
      };

      final student = StudentInfo.fromJson(json);

      expect(student.id, 1);
      expect(student.totalQuizzes, 25);
      expect(student.avgScore, 85.3);
      expect(student.bestScore, 100.0);
    });

    test('fromJson handles zero-quiz user (all stats = 0)', () {
      final json = {
        'id': 3,
        'username': 'newbie',
        'created_at': '2026-07-24T10:00:00',
        'total_quizzes': 0,
        'avg_score': 0,
        'best_score': 0,
        'total_words_tested': 0,
      };

      final student = StudentInfo.fromJson(json);

      expect(student.totalQuizzes, 0);
      expect(student.avgScore, 0.0);
    });
  });

  group('LoginRequest / RegisterRequest', () {
    test('LoginRequest.toJson matches backend format', () {
      const req = LoginRequest(username: 'alice', password: 'secret123');
      final json = req.toJson();

      expect(json['username'], 'alice');
      expect(json['password'], 'secret123');
    });

    test('RegisterRequest.toJson with bookSchema', () {
      const req = RegisterRequest(
        username: 'alice',
        password: 'secret123',
        bookSchema: 'grade6_vol1',
      );
      final json = req.toJson();

      expect(json['book_schema'], 'grade6_vol1');
    });

    test('RegisterRequest.toJson without bookSchema omits the field', () {
      const req = RegisterRequest(username: 'alice', password: 'secret123');
      final json = req.toJson();

      expect(json.containsKey('book_schema'), isFalse);
    });
  });
}
