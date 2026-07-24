import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../domain/mappers/learning_record_mapper.dart';
import '../domain/models/learning_record.dart' as domain;
import '../models/group_memory.dart' as dto;

class GroupLearningRepository {
  GroupLearningRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<dto.GroupHistoryResponse> submitHistory(
    dto.GroupHistoryRequest request,
  ) async {
    final response = await _dio.post(
      ApiPaths.groupLearningHistory,
      data: request.toJson(),
    );
    return dto.GroupHistoryResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<domain.LearningHistory> getHistory({
    String? bookSchema,
    int? unitId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (bookSchema != null) queryParams['book_schema'] = bookSchema;
    if (unitId != null) queryParams['unit_id'] = unitId;

    final response = await _dio.get(
      ApiPaths.groupLearningHistory,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return LearningRecordMapper.fromFullDto(
      dto.GroupHistoryFull.fromJson(response.data as Map<String, dynamic>),
    );
  }
}
