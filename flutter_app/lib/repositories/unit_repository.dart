import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../domain/mappers/unit_mapper.dart';
import '../domain/models/unit.dart' as domain;
import '../models/unit.dart' as dto;

class UnitRepository {
  UnitRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<List<domain.Unit>> getUnits({String? bookSchema}) async {
    final queryParams = <String, dynamic>{};
    if (bookSchema != null) queryParams['book_schema'] = bookSchema;

    final response = await _dio.get(
      ApiPaths.units,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final list = response.data as List<dynamic>;
    return list
        .map(
          (u) => UnitMapper.fromBriefDto(
            dto.UnitBrief.fromJson(u as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }
}
