import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

import '../constants/app_constants.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/error_interceptor.dart';
import '../network/interceptors/logging_interceptor.dart';
import '../network/interceptors/retry_interceptor.dart';

/// Singleton [Dio] instance pre-configured for the VocabularyMemorization API.
///
/// Responsibilities:
/// - Apply the `/api` prefix to every request.
/// - Manage Flask session cookies via [PersistCookieJar].
/// - Attach auth, error, and logging interceptors.
///
/// Usage:
/// ```dart
/// final client = ApiClient.instance.dio;
/// final response = await client.get(ApiPaths.me);
/// ```
class ApiClient {
  ApiClient._();

  static ApiClient? _instance;
  late final Dio _dio;
  late final PersistCookieJar _cookieJar;

  /// Returns the singleton [ApiClient].
  factory ApiClient({String? baseUrl}) {
    _instance ??= ApiClient._().._init(baseUrl: baseUrl);
    return _instance!;
  }

  /// The configured [Dio] instance.
  Dio get dio => _dio;

  /// The persistent cookie jar for session management.
  PersistCookieJar get cookieJar => _cookieJar;

  void _init({String? baseUrl}) {
    _cookieJar = PersistCookieJar(
      ignoreExpires: false,
    );

    _dio = Dio(BaseOptions(
      baseUrl: '${baseUrl ?? AppConstants.baseUrl}${AppConstants.apiPrefix}',
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 500,
    ));

    _dio.interceptors.addAll([
      CookieManager(_cookieJar),
      AuthInterceptor(),
      RetryInterceptor(),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  /// Reset the singleton (useful for testing or logout).
  static void reset() {
    _instance?._dio.close();
    _instance = null;
  }
}
