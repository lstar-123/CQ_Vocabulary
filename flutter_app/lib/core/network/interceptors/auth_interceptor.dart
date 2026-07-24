import 'package:dio/dio.dart';

/// Attaches the current session cookie to outgoing requests.
///
/// The [CookieManager] from dio_cookie_manager handles automatic
/// cookie storage and attachment. This interceptor adds supplementary
/// auth-related headers or performs session-validity checks.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Session cookie is handled by CookieManager automatically.
    // This interceptor is a hook point for future JWT migration
    // or custom auth headers.
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Session expired or not authenticated.
      // The ErrorInterceptor normalizes this into an AuthException.
    }
    handler.next(err);
  }
}
