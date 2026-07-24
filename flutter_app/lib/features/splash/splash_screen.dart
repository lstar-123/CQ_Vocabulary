import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../state/providers/auth_provider.dart';

/// The first screen shown at app launch.
///
/// While the [authNotifierProvider] is loading (restoring session),
/// a branded splash is displayed. Once the check completes, the
/// router's redirect logic sends the user to the correct destination
/// — no imperative navigation needed here.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    // Once the session check finishes, GoRouter's redirect takes over.
    // If still loading, show the splash.
    if (authState is AsyncLoading) {
      return _SplashBody(theme: Theme.of(context));
    }

    // On error, also show splash briefly then redirect will go to login.
    if (authState is AsyncError) {
      return _SplashBody(theme: Theme.of(context));
    }

    // Authenticated or not — the router redirect handles routing.
    // Use addPostFrameCallback to avoid build-during-build issues.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAuth = authState.valueOrNull != null;
      final target = isAuth ? AppRouter.homePath : AppRouter.loginPath;
      context.go(target);
    });

    return _SplashBody(theme: Theme.of(context));
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 44,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Vocabulary\nMemorization',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
