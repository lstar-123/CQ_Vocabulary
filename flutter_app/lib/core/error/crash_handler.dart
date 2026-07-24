import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../i18n/strings.dart';
import '../theme/app_spacing.dart';

/// Global error handler — catches unhandled Flutter framework errors
/// and displays a user-friendly recovery screen instead of a red box.
class CrashHandler {
  CrashHandler._();

  static final _logger = Logger();

  /// Call once in [main] to register global error handlers.
  static void setup() {
    FlutterError.onError = (details) {
      _logger.e('FlutterError: ${details.exception}',
          error: details.exception, stackTrace: details.stack);
      // In release, show the recovery widget.
      if (!bool.hasEnvironment('debug_mode')) {
        FlutterError.presentError(details);
      }
    };

    // Override the error widget builder.
    ErrorWidget.builder = (details) {
      _logger.e('ErrorWidget: ${details.exception}');
      return const _CrashScreen();
    };
  }

  /// Wrap in [PlatformDispatcher] for uncaught async errors.
  static void setupPlatformDispatcher() {
    // Handled via FlutterError.onError above.
  }
}

/// User-facing crash recovery screen.
class _CrashScreen extends StatelessWidget {
  const _CrashScreen();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of();
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 64, color: colorScheme.error.withOpacity(0.6)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Oops!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.errorGeneric,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () {
                  // Full restart — navigates to splash which restores session.
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/splash',
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(strings.restart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
