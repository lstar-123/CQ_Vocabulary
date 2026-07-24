import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Debug interceptor that logs every request and response.
///
/// Enabled only in debug mode. In release builds the [Logger]
/// level is set to [Level.off] so no output is produced.
class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 0,
      lineLength: 120,
      colors: false,
      printEmojis: false,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d(
      '⟶ ${options.method} ${options.uri}\n'
      '  headers: ${options.headers}\n'
      '  query: ${options.queryParameters}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d(
      '⟵ ${response.statusCode} ${response.requestOptions.uri}\n'
      '  body: ${_truncate(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.w(
      '✗ ${err.response?.statusCode} ${err.requestOptions.uri}\n'
      '  error: ${err.message}\n'
      '  body: ${_truncate(err.response?.data)}',
    );
    handler.next(err);
  }

  String _truncate(dynamic data) {
    final s = data.toString();
    return s.length > 500 ? '${s.substring(0, 500)}...' : s;
  }
}
