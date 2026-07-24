import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/word.dart' as domain;
import '../../services/audio_service.dart';
import '../../state/providers/group_learning_provider.dart';

/// Parameters for Group Learning.
class GroupParams {
  const GroupParams({
    required this.unitId,
    required this.unitName,
    this.bookSchema,
  });

  final int unitId;
  final String unitName;
  final String? bookSchema;
}

/// Group Learning — the core memorization experience.
///
/// Phases: loading → memory → spelling → wrongReview → summary
class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({
    super.key,
    required this.unitId,
    required this.unitName,
    this.bookSchema,
  });

  final int unitId;
  final String unitName;
  final String? bookSchema;

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  bool _isFlipped = false;
  final _spellCtrl = TextEditingController();
  final _spellFocus = FocusNode();
  bool _spellChecked = false;
  bool _spellLastCorrect = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(groupLearningNotifierProvider.notifier).init(
            unitId: widget.unitId,
            bookSchema: widget.bookSchema,
          );
    });
  }

  @override
  void dispose() {
    _spellCtrl.dispose();
    _spellFocus.dispose();
    super.dispose();
  }

  // ── Audio ──────────────────────────────────────────────────

  Future<void> _playWord(String text) async {
    try {
      await ref.read(audioServiceProvider.notifier).play(text);
    } on Exception {}
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(groupLearningNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unitName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(groupLearningNotifierProvider.notifier).reset();
            context.go(AppRouter.homePath);
          },
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(err),
        data: (state) => _buildPhase(state),
      ),
    );
  }

  Widget _buildError(Object err) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref
                .read(groupLearningNotifierProvider.notifier)
                .init(unitId: widget.unitId, bookSchema: widget.bookSchema),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase(GroupLearningState state) {
    return switch (state.phase) {
      GroupPhase.loading =>
        const Center(child: CircularProgressIndicator()),
      GroupPhase.memory => _MemoryPhase(
          state: state,
          isFlipped: _isFlipped,
          onFlip: () => setState(() => _isFlipped = !_isFlipped),
          onRemembered: () {
            setState(() => _isFlipped = false);
            ref.read(groupLearningNotifierProvider.notifier).markRemembered();
          },
          onForgot: () {
            setState(() => _isFlipped = false);
            ref.read(groupLearningNotifierProvider.notifier).markForgot();
          },
          onPlay: _playWord,
        ),
      GroupPhase.spelling => _SpellingPhase(
          state: state,
          controller: _spellCtrl,
          focusNode: _spellFocus,
          checked: _spellChecked,
          lastCorrect: _spellLastCorrect,
          onSubmit: (answer) {
            final ok = ref
                .read(groupLearningNotifierProvider.notifier)
                .submitSpelling(answer);
            setState(() {
              _spellChecked = true;
              _spellLastCorrect = ok;
            });
          },
          onNext: () {
            setState(() {
              _spellChecked = false;
              _spellCtrl.clear();
            });
            ref
                .read(groupLearningNotifierProvider.notifier)
                .advanceSpelling();
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _spellFocus.requestFocus());
          },
          onPlay: _playWord,
        ),
      GroupPhase.wrongReview => _WrongReviewPhase(
          state: state,
          isFlipped: _isFlipped,
          onFlip: () => setState(() => _isFlipped = !_isFlipped),
          onCorrect: () {
            setState(() => _isFlipped = false);
            ref
                .read(groupLearningNotifierProvider.notifier)
                .markWrongCorrect();
          },
          onStillWrong: () {
            setState(() => _isFlipped = false);
            ref
                .read(groupLearningNotifierProvider.notifier)
                .markWrongStillWrong();
          },
          onPlay: _playWord,
        ),
      GroupPhase.summary => _SummaryPhase(
          state: state,
          onDone: () {
            ref.read(groupLearningNotifierProvider.notifier).reset();
            context.go(AppRouter.homePath);
          },
        ),
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// Memory Phase — Anki-style card flip
// ═══════════════════════════════════════════════════════════════

class _MemoryPhase extends StatelessWidget {
  const _MemoryPhase({
    required this.state,
    required this.isFlipped,
    required this.onFlip,
    required this.onRemembered,
    required this.onForgot,
    required this.onPlay,
  });

  final GroupLearningState state;
  final bool isFlipped;
  final VoidCallback onFlip;
  final VoidCallback onRemembered;
  final VoidCallback onForgot;
  final Future<void> Function(String) onPlay;

  @override
  Widget build(BuildContext context) {
    final word = state.currentWord;
    if (word == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        _ProgressBar(state: state),
        Expanded(
          child: GestureDetector(
            onTap: onFlip,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutBack,
                child: isFlipped
                    ? _FlippedCard(
                        word: word,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        onRemembered: onRemembered,
                        onForgot: onForgot,
                        onPlay: onPlay,
                      )
                    : _FrontCard(
                        word: word,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FrontCard extends StatelessWidget {
  const _FrontCard({
    required this.word,
    required this.colorScheme,
    required this.textTheme,
  });

  final domain.Word word;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('front-${word.id}'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            word.english,
            textAlign: TextAlign.center,
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Text(
              'Tap to reveal',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlippedCard extends StatelessWidget {
  const _FlippedCard({
    required this.word,
    required this.colorScheme,
    required this.textTheme,
    required this.onRemembered,
    required this.onForgot,
    required this.onPlay,
  });

  final domain.Word word;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onRemembered;
  final VoidCallback onForgot;
  final Future<void> Function(String) onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('back-${word.id}'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: colorScheme.tertiary.withOpacity(0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.volume_up_rounded, color: colorScheme.primary),
            iconSize: 32,
            onPressed: () => onPlay(word.english),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            word.chinese,
            textAlign: TextAlign.center,
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            word.english,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onForgot,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Forgot'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRemembered,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Remembered'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Spelling Phase — type the word
// ═══════════════════════════════════════════════════════════════

class _SpellingPhase extends StatelessWidget {
  const _SpellingPhase({
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.checked,
    required this.lastCorrect,
    required this.onSubmit,
    required this.onNext,
    required this.onPlay,
  });

  final GroupLearningState state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool checked;
  final bool lastCorrect;
  final void Function(String) onSubmit;
  final VoidCallback onNext;
  final Future<void> Function(String) onPlay;

  @override
  Widget build(BuildContext context) {
    final word = state.currentWord;
    if (word == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        _ProgressBar(state: state),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => onPlay(word.english),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                      horizontal: AppSpacing.xl,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.volume_up_outlined,
                            size: 28, color: colorScheme.primary),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          word.chinese,
                          style: textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (checked)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: lastCorrect
                          ? Colors.green.withOpacity(0.08)
                          : colorScheme.error.withOpacity(0.08),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          lastCorrect ? Icons.check_circle : Icons.cancel,
                          size: 18,
                          color:
                              lastCorrect ? Colors.green : colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lastCorrect ? 'Correct!' : 'Answer: ${word.english}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: lastCorrect
                                  ? Colors.green
                                  : colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  textCapitalization: TextCapitalization.none,
                  enabled: !checked,
                  onSubmitted: checked ? (_) {} : onSubmit,
                  decoration: InputDecoration(
                    hintText: 'Type the English word…',
                    prefixIcon: const Icon(Icons.edit_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: checked
              ? SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: onNext,
                    child: const Text('Next'),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => onSubmit(controller.text),
                    child: const Text('Submit'),
                  ),
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Wrong Review Phase
// ═══════════════════════════════════════════════════════════════

class _WrongReviewPhase extends StatelessWidget {
  const _WrongReviewPhase({
    required this.state,
    required this.isFlipped,
    required this.onFlip,
    required this.onCorrect,
    required this.onStillWrong,
    required this.onPlay,
  });

  final GroupLearningState state;
  final bool isFlipped;
  final VoidCallback onFlip;
  final VoidCallback onCorrect;
  final VoidCallback onStillWrong;
  final Future<void> Function(String) onPlay;

  @override
  Widget build(BuildContext context) {
    if (state.wrongWords.isEmpty) return const SizedBox.shrink();
    final idx = state.currentWordIndex;
    if (idx >= state.wrongWords.length) return const SizedBox.shrink();
    final word = state.wrongWords[idx];
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          color: colorScheme.error.withOpacity(0.05),
          child: Row(
            children: [
              Icon(Icons.replay_rounded, size: 18, color: colorScheme.error),
              const SizedBox(width: 8),
              Text(
                'Wrong Review · ${idx + 1} / ${state.wrongWords.length}',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onFlip,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: isFlipped
                  ? Container(
                      key: ValueKey('wr-${word.id}'),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.volume_up_rounded,
                                color: colorScheme.primary),
                            iconSize: 32,
                            onPressed: () => onPlay(word.english),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(word.chinese,
                              style: textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(word.english,
                              style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface
                                      .withOpacity(0.4))),
                          const SizedBox(height: AppSpacing.xl),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: onStillWrong,
                                icon: const Icon(Icons.restart_alt, size: 18),
                                label: const Text('Still Wrong'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.error),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              FilledButton.icon(
                                onPressed: onCorrect,
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Got it!'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Container(
                      key: ValueKey('wf-${word.id}'),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(word.english,
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppSpacing.xl),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusXl),
                            ),
                            child: Text('Tap to reveal',
                                style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.primary)),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Summary Phase — hero card with stats
// ═══════════════════════════════════════════════════════════════

class _SummaryPhase extends StatelessWidget {
  const _SummaryPhase({required this.state, required this.onDone});

  final GroupLearningState state;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final duration = state.finishedAt != null && state.startedAt != null
        ? state.finishedAt!.difference(state.startedAt!)
        : null;
    final mins = duration?.inMinutes ?? 0;
    final secs = duration?.inSeconds.remainder(60) ?? 0;

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
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.15),
                  colorScheme.tertiary.withOpacity(0.05),
                ],
              ),
            ),
            child: Center(
              child: Text(
                '${(state.accuracy * 100).round()}%',
                style: textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Great work! 🎉', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xl),

          // Stat cards
          Row(
            children: [
              _StatCard(
                  icon: Icons.folder_outlined,
                  value: '${state.totalGroups}',
                  label: 'Groups',
                  colorScheme: colorScheme,
                  textTheme: textTheme),
              const SizedBox(width: AppSpacing.sm),
              _StatCard(
                  icon: Icons.menu_book_rounded,
                  value: '${state.totalWords}',
                  label: 'Words',
                  colorScheme: colorScheme,
                  textTheme: textTheme),
              const SizedBox(width: AppSpacing.sm),
              _StatCard(
                  icon: Icons.timer_outlined,
                  value: '${mins}m ${secs}s',
                  label: 'Time',
                  colorScheme: colorScheme,
                  textTheme: textTheme),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _StatCard(
                  icon: Icons.check_circle_outline,
                  value: '${state.totalCorrect}',
                  label: 'Correct',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  color: Colors.green),
              const SizedBox(width: AppSpacing.sm),
              _StatCard(
                  icon: Icons.restart_alt,
                  value: '${state.totalWrong}',
                  label: 'Review',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  color: colorScheme.error),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onDone,
              child: const Text('Done'),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.colorScheme,
    required this.textTheme,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? colorScheme.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(height: 8),
            Text(value,
                style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700, color: c)),
            Text(label,
                style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Progress Bar (shared across phases)
// ═══════════════════════════════════════════════════════════════

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.state});

  final GroupLearningState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.progressLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '✓ ${state.rememberedCount} / ${state.totalWords}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.groupProgress,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
