/// Generic paginated result carrying domain models.
///
/// The UI layer consumes this type exclusively. Backend pagination
/// field-name differences ("items" vs "words") are resolved before
/// this object is constructed.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  final List<T> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  bool get hasMore => page < totalPages;
  bool get isFirst => page <= 1;
  bool get isEmpty => items.isEmpty;
}
