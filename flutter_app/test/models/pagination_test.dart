import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/models/pagination.dart';

/// Contract tests for pagination.
///
/// Verifies that both pagination formats (/api/history "items"
/// and /api/teacher/words "words") are correctly normalized.
void main() {
  group('PaginatedResponse', () {
    test('data field generic type parameter works', () {
      const page = PaginatedResponse<String>(
        data: ['a', 'b'],
        total: 10,
        page: 1,
        perPage: 2,
        totalPages: 5,
      );

      expect(page.data, ['a', 'b']);
      expect(page.hasMore, isTrue);
      expect(page.isFirst, isTrue);
    });

    test('hasMore is false on last page', () {
      const page = PaginatedResponse<String>(
        data: ['a'],
        total: 5,
        page: 5,
        perPage: 1,
        totalPages: 5,
      );

      expect(page.hasMore, isFalse);
    });

    test('map transforms data while preserving metadata', () {
      const page = PaginatedResponse<int>(
        data: [1, 2, 3],
        total: 10,
        page: 1,
        perPage: 3,
        totalPages: 4,
      );

      final mapped = page.map<String>((i) => 'item-$i');

      expect(mapped.data, ['item-1', 'item-2', 'item-3']);
      expect(mapped.total, 10);
      expect(mapped.page, 1);
      expect(mapped.totalPages, 4);
    });
  });

  group('PaginationBuilder.fromHistoryJson', () {
    test('parses /api/history response with "items" key', () {
      final json = {
        'items': [
          {
            'id': 1,
            'unit_ids': '1,2',
            'total_count': 10,
            'correct_count': 8,
            'score_pct': 80.0,
            'duration_seconds': 120,
            'book_schema': 'grade6_vol1',
            'completed_at': '2026-07-24T10:30:00',
          },
        ],
        'total': 50,
        'page': 1,
        'per_page': 10,
        'total_pages': 5,
      };

      final page = PaginationBuilder.fromHistoryJson(
        json,
        (item) => item['id'] as int,
      );

      expect(page.data, [1]);
      expect(page.total, 50);
      expect(page.page, 1);
      expect(page.perPage, 10);
      expect(page.totalPages, 5);
    });

    test('handles empty items list', () {
      final json = {
        'items': [],
        'total': 0,
        'page': 1,
        'per_page': 10,
        'total_pages': 1,
      };

      final page = PaginationBuilder.fromHistoryJson(
        json,
        (item) => item['id'] as int,
      );

      expect(page.data, isEmpty);
      expect(page.total, 0);
    });
  });

  group('PaginationBuilder.fromTeacherWordsJson', () {
    test('parses /api/teacher/words response with "words" key', () {
      final json = {
        'words': [
          {
            'id': 1,
            'unit_id': 1,
            'unit_name': 'Unit 1',
            'english': 'apple',
            'chinese': '苹果',
          },
        ],
        'total': 150,
        'page': 1,
        'per_page': 50,
        // NOTE: teacher/words does NOT return total_pages
      };

      final page = PaginationBuilder.fromTeacherWordsJson(
        json,
        (item) => item['english'] as String,
      );

      expect(page.data, ['apple']);
      expect(page.total, 150);
      expect(page.totalPages, 3); // 150 / 50 = 3
    });
  });
}
