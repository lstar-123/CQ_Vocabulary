import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../domain/mappers/quiz_mapper.dart';
import '../domain/models/quiz.dart' as domain;
import '../models/quiz_session.dart' as dto;

class QuizRepository {
  QuizRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<domain.QuizResult> submitQuiz({
    required List<int> unitIds,
    required List<dto.AnswerSubmit> answers,
    int? durationSeconds,
    String? bookSchema,
  }) async {
    final request = dto.QuizSubmitRequest(
      unitIds: unitIds,
      answers: answers,
      durationSeconds: durationSeconds,
      bookSchema: bookSchema,
    );
    final response = await _dio.post(
      ApiPaths.quizSubmit,
      data: request.toJson(),
    );
    return QuizMapper.fromSubmitResponseDto(
      dto.QuizSubmitResponse.fromJson(response.data as Map<String, dynamic>),
    );
  }
}
