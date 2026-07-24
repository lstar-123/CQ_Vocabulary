import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';

/// Unified error card used across the entire app.
///
/// Every screen that encounters an error renders this widget
/// instead of a red screen or inline error text.
class AppErrorCard extends StatelessWidget {
  const AppErrorCard({
    super.key,
    this.message,
    this.onRetry,
  });

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of();
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 48, color: colorScheme.error.withOpacity(0.6)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  message ?? strings.errorGeneric,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(strings.retry),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
