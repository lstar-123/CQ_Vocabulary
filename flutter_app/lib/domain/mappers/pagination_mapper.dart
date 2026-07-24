import '../../models/pagination.dart' as dto;
import '../models/pagination.dart' as domain;

/// Converts the DTO-layer [dto.PaginatedResponse] (which carries DTOs)
/// into a [domain.PaginatedResult] (which carries domain models).
abstract final class PaginationMapper {
  static domain.PaginatedResult<T> fromDto<T, D>(
    dto.PaginatedResponse<D> dtoPage,
    T Function(D dtoItem) mapper,
  ) {
    return domain.PaginatedResult<T>(
      items: dtoPage.data.map(mapper).toList(growable: false),
      total: dtoPage.total,
      page: dtoPage.page,
      perPage: dtoPage.perPage,
      totalPages: dtoPage.totalPages,
    );
  }
}
