import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../domain/mappers/pagination_mapper.dart';
import '../domain/mappers/quiz_mapper.dart';
import '../domain/models/pagination.dart' as domain;
import '../domain/models/quiz.dart' as domain;
import '../models/pagination.dart' as dto;
import '../models/quiz_session.dart' as dto;

class HistoryRepository {
  HistoryRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<domain.PaginatedResult<domain.QuizSession>> getHistory({
    int? unitId,
    int page = 1,
    int perPage = 10,
    String? bookSchema,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (unitId != null) queryParams['unit_id'] = unitId;
    if (bookSchema != null) queryParams['book_schema'] = bookSchema;

    final response = await _dio.get(
      ApiPaths.history,
      queryParameters: queryParams,
    );
    final dtoPage = dto.PaginationBuilder.fromHistoryJson(
      response.data as Map<String, dynamic>,
      (item) => dto.QuizSessionBrief.fromJson(item),
    );
    return PaginationMapper.fromDto(
      dtoPage,
      QuizMapper.fromBriefDto,
    );
  }

  Future<domain.QuizSessionDetail> getDetail(int sessionId) async {
    final response = await _dio.get(ApiPaths.historyDetail(sessionId));
    return QuizMapper.fromDetailDto(
      dto.QuizSessionDetail.fromJson(response.data as Map<String, dynamic>),
    );
  }
}
