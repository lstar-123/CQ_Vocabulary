import '../../models/book.dart' as dto;
import '../models/book.dart' as domain;

abstract final class BookMapper {
  static domain.Book fromDto(dto.BookInfo d) {
    return domain.Book(schema: d.schema, name: d.name);
  }
}
