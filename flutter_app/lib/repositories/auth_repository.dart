import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../domain/mappers/book_mapper.dart';
import '../domain/mappers/user_mapper.dart';
import '../domain/models/book.dart' as domain;
import '../domain/models/user.dart' as domain;
import '../models/book.dart' as dto;
import '../models/user.dart' as dto;

/// Repository for authentication operations.
///
/// All public methods return [domain] models. DTOs and JSON are
/// internal implementation details.
class AuthRepository {
  AuthRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  /// Register a new student account.
  Future<domain.User> register({
    required String username,
    required String password,
    String? bookSchema,
  }) async {
    final request = dto.RegisterRequest(
      username: username,
      password: password,
      bookSchema: bookSchema,
    );
    final response = await _dio.post(
      ApiPaths.register,
      data: request.toJson(),
    );
    return UserMapper.fromBriefDto(
      dto.UserBrief.fromJson(response.data as Map<String, dynamic>),
    );
  }

  /// Login as a student.
  Future<domain.User> login({
    required String username,
    required String password,
  }) async {
    final request = dto.LoginRequest(username: username, password: password);
    final response = await _dio.post(
      ApiPaths.login,
      data: request.toJson(),
    );
    return UserMapper.fromBriefDto(
      dto.UserBrief.fromJson(response.data as Map<String, dynamic>),
    );
  }

  /// Login as a teacher.
  Future<domain.User> teacherLogin({
    required String username,
    required String password,
  }) async {
    final request = dto.LoginRequest(username: username, password: password);
    final response = await _dio.post(
      ApiPaths.teacherLogin,
      data: request.toJson(),
    );
    return UserMapper.fromTeacherDto(
      dto.TeacherBrief.fromJson(response.data as Map<String, dynamic>),
    );
  }

  /// Logout and clear all session cookies.
  Future<void> logout() async {
    await _dio.post(ApiPaths.logout);
    // Clear persisted cookies so no session residue remains.
    await ApiClient().cookieJar.deleteAll();
  }

  /// Switch the active word book.
  Future<domain.Book> switchBook(String bookSchema) async {
    final response = await _dio.put(
      ApiPaths.switchBook,
      data: {'book_schema': bookSchema},
    );
    final result = dto.BookSwitchResult.fromJson(
      response.data as Map<String, dynamic>,
    );
    return domain.Book(schema: result.currentBook, name: result.bookName);
  }

  /// List all available word books.
  Future<List<domain.Book>> getBooks() async {
    final response = await _dio.get(ApiPaths.listBooks);
    final list = response.data as List<dynamic>;
    return list
        .map(
          (b) => BookMapper.fromDto(
            dto.BookInfo.fromJson(b as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }

  /// Get the current authenticated user.
  ///
  /// Returns `null` when no session exists.
  Future<domain.User?> me() async {
    final response = await _dio.get(ApiPaths.me);
    final data = response.data as Map<String, dynamic>;
    if (data['user'] == null && !data.containsKey('id')) {
      return null;
    }
    if (data['role'] == 'teacher') {
      return UserMapper.fromTeacherDto(
        dto.TeacherBrief.fromJson(data),
      );
    }
    return UserMapper.fromBriefDto(dto.UserBrief.fromJson(data));
  }
}
