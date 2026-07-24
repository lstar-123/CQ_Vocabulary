import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/user.dart' as domain;
import '../../repositories/auth_repository.dart';

/// Authentication state for the current session.
///
/// **Single source of truth**: every [domain.User] returned by this
/// provider comes from `GET /api/auth/me`. Login/register set the
/// session cookie then restore from `/me` — the raw login response
/// is never used directly as state.
///
/// States:
/// - [AsyncLoading] — session check or auth operation in progress.
/// - [AsyncData] with `null` — no active session (Login screen).
/// - [AsyncData] with [domain.User] — authenticated (Home screen).
/// - [AsyncError] — session check or login failed.
class AuthNotifier extends AsyncNotifier<domain.User?> {
  @override
  Future<domain.User?> build() async {
    return _restoreSession();
  }

  // ── Internal ───────────────────────────────────────────────

  /// Call `GET /api/auth/me`. Returns the [User] if a valid session
  /// cookie exists, or `null` otherwise.
  Future<domain.User?> _restoreSession() async {
    final repo = AuthRepository();
    try {
      return await repo.me();
    } on Exception {
      return null;
    }
  }

  // ── Login / Register ───────────────────────────────────────

  /// Authenticate a student.
  ///
  /// 1. Posts credentials → backend sets session cookie.
  /// 2. Calls `/me` via [_restoreSession] → all user info from backend.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final repo = AuthRepository();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.login(username: username, password: password);
      return _restoreSession();
    });
  }

  /// Authenticate a teacher.
  Future<void> teacherLogin({
    required String username,
    required String password,
  }) async {
    final repo = AuthRepository();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.teacherLogin(username: username, password: password);
      return _restoreSession();
    });
  }

  /// Register a new student account and log in.
  Future<void> register({
    required String username,
    required String password,
    String? bookSchema,
  }) async {
    final repo = AuthRepository();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.register(
        username: username,
        password: password,
        bookSchema: bookSchema,
      );
      return _restoreSession();
    });
  }

  // ── Logout ─────────────────────────────────────────────────

  /// Log out and invalidate this provider.
  ///
  /// 1. Calls `POST /api/auth/logout` + clears [PersistCookieJar].
  /// 2. Invalidates self → [build] re-runs → `_restoreSession` returns
  ///    `null` (no cookie) → state becomes [AsyncData]`(null)`.
  /// 3. All dependent providers ([currentUserProvider], etc.) auto-update.
  Future<void> logout() async {
    final repo = AuthRepository();
    try {
      await repo.logout();
    } on Exception {
      // Even if the server call fails, clear locally.
    }
    // Invalidate so build() re-runs — this also clears any other
    // providers that depend on auth state.
    ref.invalidateSelf();
  }
}

/// The top-level provider for auth state.
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, domain.User?>(
  AuthNotifier.new,
);

/// Convenience: only the current user or null.
final currentUserProvider = Provider<domain.User?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull;
});

/// Derived: whether the user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Derived: whether the user is a teacher.
final isTeacherProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isTeacher ?? false;
});
