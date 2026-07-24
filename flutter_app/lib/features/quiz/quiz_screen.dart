import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../state/providers/quiz_provider.dart';

/// Parameters for the Quiz screen.
class QuizParams {
  const QuizParams({
    required this.unitId,
    required this.unitName,
    this.bookSchema,
  });

  final int unitId;
  final String unitName;
  final String? bookSchema;
}

/// Quiz screen — question phase and result phase.
///
/// All state is in [quizNotifierProvider]. This widget only renders.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    super.key,
    required this.unitId,
    required this.unitName,
    this.bookSchema,
  });

  final int unitId;
  final String unitName;
  final String? bookSchema;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(quizNotifierProvider.notifier).loadQuiz(
            unitId: widget.unitId,
            bookSchema: widget.bookSchema,
          );
    });
  }

  void _selectAnswer(int index) {
    final notifier = ref.read(quizNotifierProvider.notifier);
    notifier.selectAnswer(index);
    // Brief pause so the user sees feedback, then advance.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) notifier.advance();
    });
  }

  Future<void> _submit() async {
    final notifier = ref.read(quizNotifierProvider.notifier);
    try {
      await notifier.submit();
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit results')),
        );
      }
    }
  }

  void _restart() {
    ref.read(quizNotifierProvider.notifier).loadQuiz(
          unitId: widget.unitId,
          bookSchema: widget.bookSchema,
        );
  }

  void _goHome() {
    ref.read(quizNotifierProvider.notifier).reset();
    context.go(AppRouter.homePath);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(quizNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.unitName)),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(err),
        data: (state) {
          if (!state.hasQuestions) {
            return _buildEmpty();
          }
          if (state.isComplete) {
            return _buildResult(state);
          }
          return _buildQuestion(state);
        },
      ),
    );
  }

  // ── Error / Empty ───────────────────────────────────────────

  Widget _buildError(Object err) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load quiz'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref.read(quizNotifierProvider.notifier).loadQuiz(
                  unitId: widget.unitId,
                  bookSchema: widget.bookSchema,
                ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        'No words to quiz',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
      ),
    );
  }

  // ── Question Phase ──────────────────────────────────────────

  Widget _buildQuestion(QuizState state) {
    final question = state.questions[state.currentIndex];
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: state.questions.length > 1
                    ? state.currentIndex / (state.questions.length - 1)
                    : 1.0,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${state.currentIndex + 1} / ${state.questions.length}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),

        // English prompt
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xxl,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.05),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.12),
                    ),
                  ),
                  child: Text(
                    question.word.english,
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Choose the correct translation',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Options
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            children: List.generate(question.options.length, (i) {
              final option = question.options[i];
              final isSelected = state.selectedIndex == i;
              final isCorrectOption = i == question.correctIndex;
              final showResult = state.selectedIndex != null;

              // Determine button style based on state.
              Color? bgColor;
              Color? borderColor;
              Color textColor = colorScheme.onSurface;

              if (showResult) {
                if (isCorrectOption) {
                  bgColor = Colors.green.withOpacity(0.1);
                  borderColor = Colors.green.withOpacity(0.3);
                  textColor = Colors.green.shade700;
                } else if (isSelected && !isCorrectOption) {
                  bgColor = colorScheme.error.withOpacity(0.1);
                  borderColor = colorScheme.error.withOpacity(0.3);
                  textColor = colorScheme.error;
                }
              } else if (isSelected) {
                bgColor = colorScheme.primary.withOpacity(0.08);
                borderColor = colorScheme.primary.withOpacity(0.2);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        showResult ? null : () => _selectAnswer(i),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      backgroundColor: bgColor,
                      side: BorderSide(
                        color: borderColor ?? colorScheme.outlineVariant,
                      ),
                      foregroundColor: textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                    ),
                    child: Text(
                      option,
                      style: textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight:
                            showResult && isCorrectOption
                                ? FontWeight.w600
                                : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Result Phase ────────────────────────────────────────────

  Widget _buildResult(QuizState state) {
    final result = state.result!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accuracy = result.totalCount > 0
        ? (result.correctCount / result.totalCount * 100).toStringAsFixed(1)
        : '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),

          // Score circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: result.scorePct >= 80
                  ? Colors.green.withOpacity(0.1)
                  : result.scorePct >= 60
                      ? Colors.orange.withOpacity(0.1)
                      : colorScheme.error.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                '${result.scorePct.round()}%',
                style: textTheme.displayLarge?.copyWith(
                  color: result.scorePct >= 80
                      ? Colors.green
                      : result.scorePct >= 60
                          ? Colors.orange
                          : colorScheme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            result.scorePct >= 90
                ? 'Excellent! 🌟'
                : result.scorePct >= 80
                    ? 'Great job! 🎉'
                    : result.scorePct >= 60
                        ? 'Keep going! 💪'
                        : 'Practice makes perfect! 📚',
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Stats cards
          Row(
            children: [
              _StatCard(
                label: 'Correct',
                value: '${result.correctCount}',
                color: Colors.green,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatCard(
                label: 'Wrong',
                value: '${result.totalCount - result.correctCount}',
                color: colorScheme.error,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatCard(
                label: 'Accuracy',
                value: '$accuracy%',
                color: colorScheme.primary,
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Submit button
          if (!state.isSubmitted)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed:
                    state.isSubmitting ? null : _submit,
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Results'),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      size: 18, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Saved',
                    style: TextStyle(color: Colors.green.shade600),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _restart,
                  child: const Text('Restart'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: _goHome,
                  child: const Text('Back Home'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Stat Card
// ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final Color color;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
