import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/core/network/interceptors/app_exception.dart';

/// Verify the sealed exception hierarchy behaves as expected.
void main() {
  group('AppException', () {
    test('each subtype has a default Chinese message', () {
      expect(const NetworkException().message, isNotEmpty);
      expect(const TimeoutException().message, isNotEmpty);
      expect(const AuthException().message, isNotEmpty);
      expect(const ForbiddenException().message, isNotEmpty);
      expect(const NotFoundException().message, isNotEmpty);
      expect(const ConflictException().message, isNotEmpty);
      expect(const ValidationException().message, isNotEmpty);
      expect(const ServerException().message, isNotEmpty);
    });

    test('custom message overrides default', () {
      const ex = NotFoundException('单词不存在');
      expect(ex.message, '单词不存在');
    });

    test('all exceptions are catchable as AppException', () {
      final AppException ex = const AuthException();
      expect(ex, isA<AppException>());
      expect(ex, isA<AuthException>());
    });

    test('exhaustive switch works with sealed class', () {
      const AppException ex = NetworkException();

      final label = switch (ex) {
        NetworkException() => 'network',
        TimeoutException() => 'timeout',
        AuthException() => 'auth',
        ForbiddenException() => 'forbidden',
        NotFoundException() => 'not_found',
        ConflictException() => 'conflict',
        ValidationException() => 'validation',
        ServerException() => 'server',
        RequestCancelledException() => 'cancelled',
        UnknownException() => 'unknown',
      };

      expect(label, 'network');
    });
  });
}
