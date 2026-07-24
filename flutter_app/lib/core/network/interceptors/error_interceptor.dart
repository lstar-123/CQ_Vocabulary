import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Translates [DioException] into domain-specific [AppException] subtypes.
///
/// This interceptor runs last in the chain and normalizes all HTTP
/// error responses into typed exceptions that the UI layer can
/// handle uniformly.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    // Network-level errors (no response from server)
    if (response == null) {
      switch (err.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          handler.reject(_wrap(err, const TimeoutException()));
          return;
        case DioExceptionType.connectionError:
          handler.reject(_wrap(err, const NetworkException()));
          return;
        case DioExceptionType.cancel:
          handler.reject(_wrap(err, const RequestCancelledException()));
          return;
        default:
          handler.reject(_wrap(err, const UnknownException()));
          return;
      }
    }

    final statusCode = response.statusCode ?? 0;
    final message = _extractErrorMessage(response.data);

    final appException = switch (statusCode) {
      400 => ValidationException(message),
      401 => const AuthException(),
      403 => const ForbiddenException(),
      404 => NotFoundException(message),
      409 => ConflictException(message),
      422 => ValidationException(message),
      500 || 502 || 503 => ServerException(message),
      _ => UnknownException('HTTP $statusCode: $message'),
    };

    handler.reject(_wrap(err, appException));
  }

  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['error'] as String?) ?? '未知错误';
    }
    return data?.toString() ?? '未知错误';
  }

  DioException _wrap(DioException original, AppException appException) {
    return DioException(
      requestOptions: original.requestOptions,
      response: original.response,
      type: original.type,
      error: appException,
      message: appException.message,
    );
  }
}
