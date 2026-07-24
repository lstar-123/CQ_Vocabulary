/// Domain model representing an available word book.
class Book {
  const Book({
    required this.schema,
    required this.name,
  });

  final String schema;
  final String name;
}
