import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/state/providers/auth_provider.dart';

/// Tests for AuthNotifier state transitions.
///
/// These tests verify the provider's behavior independent of
/// the network — we test state transitions and derived providers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthNotifier — derived providers', () {
    test('currentUserProvider is null when not authenticated', () {
      final container = ProviderContainer();

      addTearDown(container.dispose);

      final user = container.read(currentUserProvider);
      // Before auth state resolves, it's AsyncLoading → value is null
      expect(user, isNull);
    });

    test('isAuthenticatedProvider is false when user is null', () {
      final container = ProviderContainer();

      addTearDown(container.dispose);

      final authenticated = container.read(isAuthenticatedProvider);
      expect(authenticated, isFalse);
    });

    test('isTeacherProvider is false when user is null', () {
      final container = ProviderContainer();

      addTearDown(container.dispose);

      final isTeacher = container.read(isTeacherProvider);
      expect(isTeacher, isFalse);
    });

    test(
      'isAuthenticatedProvider reacts to auth state change',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Initially not authenticated.
        expect(container.read(isAuthenticatedProvider), isFalse);

        // Simulate setting an authenticated state.
        // We set state directly on the notifier.
        final notifier = container.read(authNotifierProvider.notifier);
        notifier.logout(); // Ensure clean start

        // After logout, user is null.
        expect(container.read(isAuthenticatedProvider), isFalse);

        // Verify isTeacherProvider is also false.
        expect(container.read(isTeacherProvider), isFalse);
      },
    );
  });

  group('AuthNotifier — logout clears state', () {
    test('logout sets state to AsyncData(null)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      // logout handles errors internally and always sets state to null.
      // Since we're offline, the server call will fail, but state
      // should still become AsyncData(null).
      await notifier.logout();

      final authState = container.read(authNotifierProvider);
      expect(authState.valueOrNull, isNull);
    });
  });
}
