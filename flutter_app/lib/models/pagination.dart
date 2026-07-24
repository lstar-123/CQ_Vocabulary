/// Generic paginated response wrapper.
///
/// All paginated API responses share this shape but use different
/// field names for the data list:
///   /api/history      → "items"
///   /api/teacher/words → "words"
///
/// The Repository layer normalizes both into [PaginatedResponse]
/// so the UI layer never sees the inconsistency.
library;

class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  final List<T> data;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  /// True when there are more pages to fetch.
  bool get hasMore => page < totalPages;

  /// True when this is the first page.
  bool get isFirst => page <= 1;

  /// Map the data list to a different type.
  PaginatedResponse<U> map<U>(U Function(T) mapper) {
    return PaginatedResponse<U>(
      data: data.map(mapper).toList(growable: false),
      total: total,
      page: page,
      perPage: perPage,
      totalPages: totalPages,
    );
  }
}

/// Builds a [PaginatedResponse] from the two known pagination shapes.
///
/// Usage in repositories:
/// ```dart
/// final json = await client.get('/history', queryParameters: {...});
/// final page = PaginationBuilder.fromHistoryJson(
///   json.data,
///   (item) => QuizSessionBrief.fromJson(item),
/// );
/// ```
class PaginationBuilder {
  PaginationBuilder._();

  /// Parse the /api/history pagination shape (field: "items").
  static PaginatedResponse<T> fromHistoryJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PaginatedResponse<T>(
      data: rawItems
          .map((i) => itemParser(i as Map<String, dynamic>))
          .toList(growable: false),
      total: json['total'] as int,
      page: json['page'] as int,
      perPage: json['per_page'] as int,
      totalPages: json['total_pages'] as int,
    );
  }

  /// Parse the /api/teacher/words pagination shape (field: "words").
  static PaginatedResponse<T> fromTeacherWordsJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final rawItems = json['words'] as List<dynamic>? ?? [];
    return PaginatedResponse<T>(
      data: rawItems
          .map((i) => itemParser(i as Map<String, dynamic>))
          .toList(growable: false),
      total: json['total'] as int,
      page: json['page'] as int,
      perPage: json['per_page'] as int,
      totalPages: _calcTotalPages(json['total'] as int, json['per_page'] as int),
    );
  }

  static int _calcTotalPages(int total, int perPage) {
    if (perPage <= 0) return 1;
    return (total + perPage - 1) ~/ perPage;
  }
}
