import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../domain/mappers/learning_record_mapper.dart';
import '../domain/mappers/statistics_mapper.dart';
import '../domain/models/learning_record.dart' as domain;
import '../domain/models/statistics.dart' as domain;
import '../models/group_memory.dart' as dto;
import '../models/statistics.dart' as dto;

class StatsRepository {
  StatsRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<List<domain.ScoreTrend>> getTrend({String? bookSchema}) async {
    final queryParams = <String, dynamic>{};
    if (bookSchema != null) queryParams['book_schema'] = bookSchema;

    final response = await _dio.get(
      ApiPaths.statsTrend,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final list = response.data as List<dynamic>;
    return list
        .map(
          (t) => StatisticsMapper.fromTrendPointDto(
            dto.TrendPoint.fromJson(t as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }

  Future<domain.StudySummary> getSummary({String? bookSchema}) async {
    final queryParams = <String, dynamic>{};
    if (bookSchema != null) queryParams['book_schema'] = bookSchema;

    final response = await _dio.get(
      ApiPaths.statsSummary,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return StatisticsMapper.fromSummaryDto(
      dto.StatsSummary.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<List<domain.LearningRecord>> getGroupHistory({
    String? bookSchema,
  }) async {
    final queryParams = <String, dynamic>{};
    if (bookSchema != null) queryParams['book_schema'] = bookSchema;

    final response = await _dio.get(
      ApiPaths.statsGroupHistory,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final list = response.data as List<dynamic>;
    return list
        .map(
          (r) => LearningRecordMapper.fromDto(
            dto.GroupMemoryRecord.fromJson(r as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }
}
