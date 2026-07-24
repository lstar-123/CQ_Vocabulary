import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/models/word.dart' as domain;
import '../../services/audio_service.dart';
import '../../state/providers/spelling_provider.dart';

/// Parameters passed to the Spelling screen via GoRouter extra.
class SpellingParams {
  const SpellingParams({
    required this.unitId,
    required this.unitName,
    this.bookSchema,
  });

  final int unitId;
  final String unitName;
  final String? bookSchema;
}

/// Spelling mode screen.
///
/// Shows Chinese + audio → user types English → submit → check result →
/// next word. All state lives in [spellingNotifierProvider].
class SpellingScreen extends ConsumerStatefulWidget {
  const SpellingScreen({
    super.key,
    required this.unitId,
    required this.unitName,
    this.bookSchema,
  });

  final int unitId;
  final String unitName;
  final String? bookSchema;

  @override
  ConsumerState<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends ConsumerState<SpellingScreen> {
  final _inputFocus = FocusNode();
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load words on first build.
    Future.microtask(() {
      ref.read(spellingNotifierProvider.notifier).init(
            unitId: widget.unitId,
            bookSchema: widget.bookSchema,
          );
    });
  }

  @override
  void dispose() {
    _inputFocus.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────

  void _submit() {
    final notifier = ref.read(spellingNotifierProvider.notifier);
    final state = ref.read(spellingNotifierProvider).requireValue;
    if (state.currentInput.trim().isEmpty) return;
    if (state.showResult) return;
    notifier.submit();
  }

  void _next() {
    final notifier = ref.read(spellingNotifierProvider.notifier);
    notifier.nextWord();
    _textCtrl.clear();
    // Auto-focus for next word.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocus.requestFocus();
    });
  }

  void _prev() {
    final notifier = ref.read(spellingNotifierProvider.notifier);
    notifier.prevWord();
    _textCtrl.clear();
    // Restore previous answer text if revisiting.
    WidgetsBinding.instance.addPostFrameCallback(() {
      final state = ref.read(spellingNotifierProvider).requireValue;
      _textCtrl.text = state.currentInput;
    });
  }

  void _skip() {
    final notifier = ref.read(spellingNotifierProvider.notifier);
    if (ref.read(spellingNotifierProvider).requireValue.showResult) return;
    notifier.skip();
  }

  Future<void> _playAudio() async {
    final word = ref.read(spellingNotifierProvider)
        .requireValue.words[ref.read(spellingNotifierProvider)
        .requireValue.currentIndex];
    try {
      await ref.read(audioServiceProvider.notifier).play(word.english);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TTS unavailable')),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(spellingNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.unitName)),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(err),
        data: (state) {
          if (state.words.isEmpty) {
            return _buildEmpty();
          }
          return _buildSpelling(state);
        },
      ),
    );
  }

  Widget _buildError(Object err) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load words'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref.read(spellingNotifierProvider.notifier).init(
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
        'No words in this unit',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
      ),
    );
  }

  Widget _buildSpelling(SpellingState state) {
    final word = state.words[state.currentIndex];
    final audioState = ref.watch(audioServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final result = state.currentResult;

    return Column(
      children: [
        // ── Progress ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: state.words.length > 1
                    ? state.currentIndex / (state.words.length - 1)
                    : 1.0,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.currentIndex + 1} / ${state.words.length}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    '✓ ${state.correctCount}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Chinese Prompt Card ─────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GestureDetector(
              onTap: _playAudio,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔊 hint
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXl,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            audioState == AudioPlayState.playing
                                ? Icons.volume_up_rounded
                                : Icons.touch_app_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            audioState == AudioPlayState.loading
                                ? 'Loading…'
                                : audioState == AudioPlayState.playing
                                    ? 'Playing…'
                                    : 'Tap to listen',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Chinese word
                    Text(
                      word.chinese,
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Answer Input ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            children: [
              // Result feedback
              if (result != null) _buildResultBanner(result, word, colorScheme),

              // Text field
              TextField(
                controller: _textCtrl,
                focusNode: _inputFocus,
                autofocus: true,
                enabled: !state.showResult,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.none,
                onChanged: (v) =>
                    ref.read(spellingNotifierProvider.notifier).updateInput(v),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Type the English word…',
                  prefixIcon: const Icon(Icons.edit_outlined),
                  suffixIcon: state.currentInput.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _textCtrl.clear();
                            ref
                                .read(spellingNotifierProvider.notifier)
                                .updateInput('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Action Buttons ────────────────────────
              if (!state.showResult) _buildSubmitRow(state)
              else _buildResultRow(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  // ── Submit Mode Buttons ────────────────────────────────────

  Widget _buildSubmitRow(SpellingState state) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _skip,
            icon: const Icon(Icons.skip_next, size: 20),
            label: const Text('Skip'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed:
                state.currentInput.trim().isNotEmpty ? _submit : null,
            icon: const Icon(Icons.check, size: 20),
            label: const Text('Submit'),
          ),
        ),
      ],
    );
  }

  // ── Result Mode Buttons ────────────────────────────────────

  Widget _buildResultRow() {
    final notifier = ref.read(spellingNotifierProvider.notifier);

    return Row(
      children: [
        // Prev
        Expanded(
          child: OutlinedButton.icon(
            onPressed: notifier.hasPrev ? _prev : null,
            icon: const Icon(Icons.arrow_back, size: 20),
            label: const Text('Prev'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Replay audio
        IconButton.filled(
          onPressed: _playAudio,
          icon: const Icon(Icons.volume_up_rounded),
          tooltip: 'Replay',
        ),
        const SizedBox(width: AppSpacing.sm),
        // Next
        Expanded(
          child: FilledButton.icon(
            onPressed: notifier.hasNext ? _next : null,
            icon: const Icon(Icons.arrow_forward, size: 20),
            label: Text(notifier.hasNext ? 'Next' : 'Finish'),
          ),
        ),
      ],
    );
  }

  // ── Result Banner ──────────────────────────────────────────

  Widget _buildResultBanner(
    SpellingResult result,
    domain.Word word,
    ColorScheme colorScheme,
  ) {
    final isCorrect = result.isCorrect;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isCorrect
              ? Colors.green.withOpacity(0.08)
              : colorScheme.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isCorrect
                ? Colors.green.withOpacity(0.2)
                : colorScheme.error.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  size: 18,
                  color: isCorrect ? Colors.green : colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  isCorrect ? 'Correct' : 'Wrong',
                  style: textTheme.labelLarge?.copyWith(
                    color: isCorrect ? Colors.green : colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (!isCorrect && !result.skipped) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Answer: ${word.english}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (result.skipped) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Answer: ${word.english}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
