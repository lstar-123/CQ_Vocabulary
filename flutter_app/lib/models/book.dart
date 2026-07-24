/// Book DTO — represents a word book available in the system.
///
/// Backend source: BOOK_SCHEMAS dict
///   GET /api/auth/books
///   GET /api/teacher/books
library;

class BookInfo {
  const BookInfo({
    required this.schema,
    required this.name,
  });

  final String schema; // "grade6_vol1", "senior_compulsory_1"
  final String name; // "六年级上册", "高中必修一"

  factory BookInfo.fromJson(Map<String, dynamic> json) {
    return BookInfo(
      schema: json['schema'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schema': schema,
      'name': name,
    };
  }
}

/// Response from PUT /api/auth/book.
class BookSwitchResult {
  const BookSwitchResult({
    required this.currentBook,
    required this.bookName,
  });

  final String currentBook;
  final String bookName;

  factory BookSwitchResult.fromJson(Map<String, dynamic> json) {
    return BookSwitchResult(
      currentBook: json['current_book'] as String,
      bookName: json['book_name'] as String,
    );
  }
}
