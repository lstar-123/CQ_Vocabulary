import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../domain/mappers/book_mapper.dart';
import '../domain/mappers/pagination_mapper.dart';
import '../domain/mappers/quiz_mapper.dart';
import '../domain/mappers/user_mapper.dart';
import '../domain/mappers/word_mapper.dart';
import '../domain/models/book.dart' as domain;
import '../domain/models/pagination.dart' as domain;
import '../domain/models/quiz.dart' as domain;
import '../domain/models/user.dart' as domain;
import '../domain/models/word.dart' as domain;
import '../models/book.dart' as dto;
import '../models/pagination.dart' as dto;
import '../models/quiz_session.dart' as dto;
import '../models/user.dart' as dto;
import '../models/word.dart' as dto;

class TeacherRepository {
  TeacherRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  // ── Student Management ─────────────────────────────────────

  Future<List<domain.StudentSummary>> getStudents() async {
    final response = await _dio.get(ApiPaths.teacherStudents);
    final list = response.data as List<dynamic>;
    return list
        .map(
          (s) => UserMapper.fromStudentInfoDto(
            dto.StudentInfo.fromJson(s as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }

  Future<domain.StudentSummary> getStudentDetail(int studentId) async {
    final response = await _dio.get(
      ApiPaths.teacherStudentDetail(studentId),
    );
    return UserMapper.fromStudentInfoDto(
      dto.StudentInfo.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<List<domain.QuizSession>> getStudentSessions(int studentId) async {
    final response = await _dio.get(
      ApiPaths.teacherStudentSessions(studentId),
    );
    final list = response.data as List<dynamic>;
    return list
        .map(
          (s) => QuizMapper.fromBriefDto(
            dto.QuizSessionBrief.fromJson(s as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }

  Future<domain.QuizSessionDetail> getStudentSessionDetail(
    int studentId,
    int sessionId,
  ) async {
    final response = await _dio.get(
      ApiPaths.teacherStudentSessionDetail(studentId, sessionId),
    );
    return QuizMapper.fromDetailDto(
      dto.QuizSessionDetail.fromJson(response.data as Map<String, dynamic>),
    );
  }

  // ── Books ──────────────────────────────────────────────────

  Future<List<domain.Book>> getBooks() async {
    final response = await _dio.get(ApiPaths.teacherBooks);
    final list = response.data as List<dynamic>;
    return list
        .map(
          (b) => BookMapper.fromDto(
            dto.BookInfo.fromJson(b as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }

  // ── Word Management ────────────────────────────────────────

  Future<domain.PaginatedResult<domain.Word>> getWords({
    int? unitId,
    int page = 1,
    int perPage = 50,
    String? bookSchema,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (unitId != null) queryParams['unit_id'] = unitId;
    if (bookSchema != null) queryParams['book_schema'] = bookSchema;

    final response = await _dio.get(
      ApiPaths.teacherWords,
      queryParameters: queryParams,
    );
    final dtoPage = dto.PaginationBuilder.fromTeacherWordsJson(
      response.data as Map<String, dynamic>,
      (item) => dto.WordBrief.fromJson(item),
    );
    return PaginationMapper.fromDto(dtoPage, WordMapper.fromBriefDto);
  }

  Future<domain.Word> createWord({
    required int unitId,
    required String english,
    required String chinese,
    String? bookSchema,
  }) async {
    final request = dto.CreateWordRequest(
      unitId: unitId,
      english: english,
      chinese: chinese,
      bookSchema: bookSchema,
    );
    final response = await _dio.post(
      ApiPaths.teacherWords,
      data: request.toJson(),
    );
    return WordMapper.fromBriefDto(
      dto.WordBrief.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<domain.Word> updateWord(
    int wordId, {
    int? unitId,
    String? english,
    String? chinese,
    String? bookSchema,
  }) async {
    final request = dto.UpdateWordRequest(
      unitId: unitId,
      english: english,
      chinese: chinese,
      bookSchema: bookSchema,
    );
    final response = await _dio.put(
      ApiPaths.teacherWordDetail(wordId),
      data: request.toJson(),
    );
    return WordMapper.fromBriefDto(
      dto.WordBrief.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<void> deleteWord(int wordId, {String? bookSchema}) async {
    final queryParams = <String, dynamic>{};
    if (bookSchema != null) queryParams['book_schema'] = bookSchema;

    await _dio.delete(
      ApiPaths.teacherWordDetail(wordId),
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }
}
