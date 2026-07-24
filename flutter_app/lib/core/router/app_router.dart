import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/flashcard/flashcard_screen.dart';
import '../../features/group/group_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/login/login_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/spelling/spelling_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../../state/providers/auth_provider.dart';
import 'page_transitions.dart';

/// Centralized route definitions with auth guard.
///
/// The auth redirect is enforced at the router level — individual
/// pages never check login state. When [authNotifierProvider] changes
/// (login, logout, session restore), GoRouter re-evaluates the
/// redirect via [refreshListenable].
class AppRouter {
  AppRouter._();

  // ── Route Names ────────────────────────────────────────────

  static const String splash = 'splash';
  static const String login = 'login';
  static const String home = 'home';
  static const String flashcard = 'flashcard';
  static const String spelling = 'spelling';
  static const String quiz = 'quiz';
  static const String history = 'history';
  static const String groupLearning = 'groupLearning';

  // (future routes)
  static const String stats = 'stats';
  static const String profile = 'profile';

  // ── Route Paths ────────────────────────────────────────────

  static const String splashPath = '/splash';
  static const String loginPath = '/login';
  static const String homePath = '/';
  static const String flashcardPath = '/flashcard';
  static const String spellingPath = '/spelling';
  static const String quizPath = '/quiz';
  static const String historyPath = '/history';
  static const String groupPath = '/group-learning';
  static const String statsPath = '/stats';
  static const String profilePath = '/profile';

  static const String initialRoute = splashPath;

  /// Creates the [GoRouter] instance.
  ///
  /// [ref] is used to listen to auth state changes. The router
  /// must be created exactly once; callers should memoize it.
  static GoRouter createRouter(Ref ref) {
    final authChangeNotifier = ValueNotifier<int>(0);

    ref.listen(authNotifierProvider, (previous, next) {
      authChangeNotifier.value++;
    });

    return GoRouter(
      initialLocation: initialRoute,
      refreshListenable: authChangeNotifier,
      redirect: (context, state) {
        final container = ProviderScope.containerOf(context);
        final authState = container.read(authNotifierProvider);
        final isAuthenticated = authState.valueOrNull != null;
        final isAuthLoading = authState is AsyncLoading;
        final onSplash = state.matchedLocation == splashPath;
        final onLogin = state.matchedLocation == loginPath;

        if (isAuthLoading) {
          return onSplash ? null : splashPath;
        }
        if (!isAuthenticated) {
          if (onSplash || onLogin) return null;
          return loginPath;
        }
        if (onSplash || onLogin) {
          return homePath;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: splashPath,
          name: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: loginPath,
          name: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: homePath,
          name: home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: flashcardPath,
          name: flashcard,
          builder: (context, state) {
            final params = state.extra as FlashcardParams?;
            return FlashcardScreen(
              unitId: params?.unitId ?? 0,
              unitName: params?.unitName ?? '',
              bookSchema: params?.bookSchema,
            );
          },
        ),
        GoRoute(
          path: spellingPath,
          name: spelling,
          builder: (context, state) {
            final params = state.extra as SpellingParams?;
            return SpellingScreen(
              unitId: params?.unitId ?? 0,
              unitName: params?.unitName ?? '',
              bookSchema: params?.bookSchema,
            );
          },
        ),
        GoRoute(
          path: quizPath,
          name: quiz,
          builder: (context, state) {
            final params = state.extra as QuizParams?;
            return QuizScreen(
              unitId: params?.unitId ?? 0,
              unitName: params?.unitName ?? '',
              bookSchema: params?.bookSchema,
            );
          },
        ),
        GoRoute(
          path: groupPath,
          name: groupLearning,
          builder: (context, state) {
            final params = state.extra as GroupParams?;
            return GroupScreen(
              unitId: params?.unitId ?? 0,
              unitName: params?.unitName ?? '',
              bookSchema: params?.bookSchema,
            );
          },
        ),
        GoRoute(
          path: historyPath,
          name: history,
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: statsPath,
          name: stats,
          builder: (context, state) => const StatsScreen(),
        ),
        GoRoute(
          path: profilePath,
          name: profile,
          builder: (context, state) =>
              const _PlaceholderPage(title: 'Profile'),
        ),
      ],
    );
  }
}

/// Placeholder page for routes not yet implemented.
class _PlaceholderPage extends ConsumerWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.construction_rounded,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$title — Coming Soon',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (user != null) ...[
              const SizedBox(height: 8),
              Text(
                'Logged in as ${user.username} (${user.role.name})',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
