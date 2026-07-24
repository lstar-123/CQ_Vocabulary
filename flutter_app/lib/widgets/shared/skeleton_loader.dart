import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Shimmer skeleton loading placeholder.
///
/// Replaces [CircularProgressIndicator] throughout the app for a
/// polished loading experience. Animates a gradient shimmer across
/// rounded rectangular shapes matching the expected content layout.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.count = 3,
    this.height = 16,
    this.spacing = AppSpacing.sm,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius = AppSpacing.radiusSm,
  });

  final int count;
  final double height;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.onSurface.withOpacity(0.06);
    final highlight = colorScheme.onSurface.withOpacity(0.12);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final gradient = LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value, 0),
          colors: [base, highlight, base],
        );
        return Padding(
          padding: widget.padding,
          child: Column(
            children: List.generate(widget.count, (i) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < widget.count - 1 ? widget.spacing : 0,
                ),
                child: Container(
                  height: widget.height,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(widget.borderRadius),
                    gradient: gradient,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Card-shaped skeleton — matches the [Card] component layout.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 88});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: SizedBox(height: height),
      ),
    );
  }
}

/// Page skeleton — header + cards for full-page loading.
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: AppSpacing.lg),
        SkeletonCard(height: 160),
        SkeletonCard(height: 88),
        SkeletonCard(height: 88),
        SkeletonCard(height: 88),
      ],
    );
  }
}
