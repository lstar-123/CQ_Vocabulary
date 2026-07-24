import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Light page transitions used across the app.
///
/// Registered via GoRouter's `pageBuilder` for routes that benefit
/// from animated transitions.
class AppPageTransitions {
  AppPageTransitions._();

  /// A subtle fade + slight slide-up transition.
  static CustomTransitionPage fadeUpTransition({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
