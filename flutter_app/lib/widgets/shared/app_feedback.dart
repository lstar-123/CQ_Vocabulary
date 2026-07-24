import 'package:flutter/material.dart';

/// Unified user feedback — SnackBar / Toast.
///
/// Every screen calls [AppFeedback] methods instead of building
/// its own [SnackBar] inline. This guarantees consistent styling.
abstract final class AppFeedback {
  /// Show a brief success/neutral message.
  static void toast(BuildContext context, String message) {
    _show(context, message, null, const Duration(seconds: 2));
  }

  /// Show an error message.
  static void error(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    _show(
      context,
      message,
      cs.error,
      const Duration(seconds: 3),
      icon: Icons.error_outline,
    );
  }

  /// Show a success message.
  static void success(BuildContext context, String message) {
    _show(
      context,
      message,
      Colors.green,
      const Duration(seconds: 2),
      icon: Icons.check_circle_outline,
    );
  }

  /// Show a network status banner.
  static void networkBanner(BuildContext context, {required bool online}) {
    ScaffoldMessenger.of(context).clearMaterialBanners();
    if (!online) {
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content: const Text('No internet connection'),
          leading: const Icon(Icons.cloud_off),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          actions: [
            TextButton(
              onPressed: () =>
                  ScaffoldMessenger.of(context).clearMaterialBanners(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }
  }

  static void _show(
    BuildContext context,
    String message,
    Color? color,
    Duration duration, {
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: duration,
          backgroundColor: color?.withOpacity(0.9),
        ),
      );
  }
}
