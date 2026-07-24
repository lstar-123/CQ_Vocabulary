/// Sealed hierarchy of all possible API errors.
///
/// Widgets catch [AppException] and map each subtype to the appropriate
/// user-facing message without inspecting strings or status codes.
sealed class AppException implements Exception {
  const AppException([this.message = '']);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = '网络连接失败，请检查网络设置']);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = '请求超时，请重试']);
}

class AuthException extends AppException {
  const AuthException([super.message = '请先登录']);
}

class ForbiddenException extends AppException {
  const ForbiddenException([super.message = '没有访问权限']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = '请求的资源不存在']);
}

class ConflictException extends AppException {
  const ConflictException([super.message = '资源冲突']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = '请求参数错误']);
}

class ServerException extends AppException {
  const ServerException([super.message = '服务器错误，请稍后重试']);
}

class RequestCancelledException extends AppException {
  const RequestCancelledException([super.message = '请求已取消']);
}

class UnknownException extends AppException {
  const UnknownException([super.message = '未知错误']);
}
