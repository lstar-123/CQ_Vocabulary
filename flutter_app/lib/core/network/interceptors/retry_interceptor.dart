import 'dart:math';

import 'package:dio/dio.dart';

/// Retry interceptor with exponential backoff.
///
/// Retries on network errors and 5xx server errors.
/// Does NOT retry on 4xx (client errors).
class RetryInterceptor extends Interceptor {
  RetryInterceptor({this.maxRetries = 3, this.baseDelayMs = 500});

  final int maxRetries;
  final int baseDelayMs;
  final _rng = Random();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final retryCount = err.requestOptions.extra['_retryCount'] as int? ?? 0;
    final shouldRetry = _shouldRetry(err) && retryCount < maxRetries;

    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    final delay = baseDelayMs * pow(2, retryCount) + _rng.nextInt(200);
    final options = err.requestOptions;
    options.extra['_retryCount'] = retryCount + 1;

    Future.delayed(Duration(milliseconds: delay), () {
      Dio().fetch(options).then(
        (response) => handler.resolve(response),
        onError: (e) => handler.next(e is DioException ? e : err),
      );
    });
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }
}
