import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../domain/mappers/phonics_mapper.dart';
import '../domain/mappers/unit_mapper.dart';
import '../domain/mappers/word_mapper.dart';
import '../domain/models/phonics.dart' as domain;
import '../domain/models/unit.dart' as domain;
import '../domain/models/word.dart' as domain;
import '../models/phonics.dart' as dto;
import '../models/unit.dart' as dto;
import '../models/word.dart' as dto;

class WordRepository {
  WordRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<List<domain.Word>> getWords({
    String? bookSchema,
    List<int>? unitIds,
    bool random = false,
  }) async {
    final queryParams = <String, dynamic>{};
    if (bookSchema != null) queryParams['book_schema'] = bookSchema;
    if (unitIds != null && unitIds.isNotEmpty) {
      queryParams['unit_ids'] = unitIds.join(',');
    }
    if (random) queryParams['random'] = '1';

    final response = await _dio.get(
      ApiPaths.words,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final list = response.data as List<dynamic>;
    return list
        .map(
          (w) => WordMapper.fromBriefDto(
            dto.WordBrief.fromJson(w as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }

  Future<List<domain.UnitWithWords>> getAllWordsGrouped({
    String? bookSchema,
  }) async {
    final queryParams = <String, dynamic>{};
    if (bookSchema != null) queryParams['book_schema'] = bookSchema;

    final response = await _dio.get(
      ApiPaths.wordsAll,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final list = response.data as List<dynamic>;
    return list
        .map(
          (u) => UnitMapper.fromUnitWithWordsDto(
            dto.UnitWithWords.fromJson(u as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }

  Future<domain.Phonics> getPhonics(
    String word, {
    String? bookSchema,
  }) async {
    final queryParams = <String, dynamic>{'word': word};
    if (bookSchema != null) queryParams['book_schema'] = bookSchema;

    final response = await _dio.get(
      ApiPaths.wordsPhonics,
      queryParameters: queryParams,
    );
    return PhonicsMapper.fromDto(
      dto.PhonicsData.fromJson(response.data as Map<String, dynamic>),
    );
  }
}
