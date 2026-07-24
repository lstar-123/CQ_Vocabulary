import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/models/word.dart' as domain;
import '../../repositories/word_repository.dart';
import '../../services/audio_service.dart';

/// Parameters passed to the Flashcard screen via GoRouter extra.
class FlashcardParams {
  const FlashcardParams({
    required this.unitId,
    required this.unitName,
    this.bookSchema,
  });

  final int unitId;
  final String unitName;
  final String? bookSchema;
}

/// Card-mode flashcard screen.
///
/// Shows one word card at a time. Tap to flip between English and
/// Chinese. A speaker button plays TTS pronunciation.
class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({
    super.key,
    required this.unitId,
    required this.unitName,
    this.bookSchema,
  });

  final int unitId;
  final String unitName;
  final String? bookSchema;

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  late Future<List<domain.Word>> _wordsFuture;
  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _wordsFuture = _loadWords();
  }

  Future<List<domain.Word>> _loadWords() async {
    final repo = WordRepository();
    return repo.getWords(
      bookSchema: widget.bookSchema,
      unitIds: [widget.unitId],
    );
  }

  void _flip() => setState(() => _isFlipped = !_isFlipped);

  void _next() {
    if (_currentIndex >= _words.length - 1) return;
    setState(() {
      _currentIndex++;
      _isFlipped = false;
    });
  }

  void _previous() {
    if (_currentIndex <= 0) return;
    setState(() {
      _currentIndex--;
      _isFlipped = false;
    });
  }

  Future<void> _playAudio(String text) async {
    try {
      await ref.read(audioServiceProvider.notifier).play(text);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TTS unavailable')),
        );
      }
    }
  }

  List<domain.Word> get _words => []; // filled by FutureBuilder

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unitName),
      ),
      body: FutureBuilder<List<domain.Word>>(
        future: _wordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Failed to load words'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() {
                      _wordsFuture = _loadWords();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final words = snapshot.data ?? [];
          if (words.isEmpty) {
            return Center(
              child: Text(
                'No words in this unit',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            );
          }

          final word = words[_currentIndex];

          return Column(
            children: [
              // ── Progress Bar ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: words.length > 1
                          ? (_currentIndex) / (words.length - 1)
                          : 1.0,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${_currentIndex + 1} / ${words.length}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Card ────────────────────────────────
              Expanded(
                child: GestureDetector(
                  onTap: _flip,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: Tween<double>(begin: 0.95, end: 1.0)
                              .animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _isFlipped
                          ? _buildBackCard(word, colorScheme, textTheme)
                          : _buildFrontCard(word, colorScheme, textTheme),
                    ),
                  ),
                ),
              ),

              // ── Bottom Controls ─────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton.filled(
                      onPressed: _currentIndex > 0 ? _previous : null,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Previous',
                    ),
                    IconButton.filled(
                      onPressed:
                          audioState == AudioPlayState.loading
                              ? null
                              : () => _playAudio(word.english),
                      icon: audioState == AudioPlayState.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              audioState == AudioPlayState.playing
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_up_outlined,
                            ),
                      tooltip: 'Pronounce',
                    ),
                    IconButton.filled(
                      onPressed: _currentIndex < words.length - 1
                          ? _next
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      tooltip: 'Next',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Front: English ──────────────────────────────────────────

  Widget _buildFrontCard(
    domain.Word word,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      key: ValueKey('${word.id}-front'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            word.english,
            textAlign: TextAlign.center,
            style: textTheme.displayMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
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

  // ── Back: Chinese ───────────────────────────────────────────

  Widget _buildBackCard(
    domain.Word word,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      key: ValueKey('${word.id}-back'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: colorScheme.tertiary.withOpacity(0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            word.chinese,
            textAlign: TextAlign.center,
            style: textTheme.displayMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            word.english,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Text(
              'Tap to hide',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
