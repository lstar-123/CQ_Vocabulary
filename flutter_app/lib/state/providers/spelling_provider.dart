import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/spelling.dart';
import '../../domain/models/word.dart' as domain;
import '../../repositories/word_repository.dart';
import '../../services/audio_service.dart';

/// Manages a full spelling session for one unit.
///
/// State transitions:
/// - `AsyncLoading` — fetching words from backend.
/// - `AsyncData` — session ready; field-level state in [SpellingState].
/// - `AsyncError` — word fetch failed.
class SpellingNotifier extends AsyncNotifier<SpellingState> {
  @override
  Future<SpellingState> build() async {
    // Initial empty state — words are loaded via init().
    return const SpellingState(
      words: [],
      currentIndex: 0,
      results: [],
      currentInput: '',
      isPlaying: false,
      showResult: false,
    );
  }

  // ── Initialisation ─────────────────────────────────────────

  /// Load words for the given unit and reset the session.
  Future<void> init({
    required int unitId,
    String? bookSchema,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = WordRepository();
      final words = await repo.getWords(
        bookSchema: bookSchema,
        unitIds: [unitId],
      );
      return SpellingState(
        words: words,
        currentIndex: 0,
        results: [],
        currentInput: '',
        isPlaying: false,
        showResult: false,
      );
    });
  }

  // ── Getters (call on AsyncData) ────────────────────────────

  SpellingState get current => state.requireValue;

  domain.Word get currentWord => current.words[current.currentIndex];

  bool get hasPrev => current.currentIndex > 0;

  bool get hasNext => current.currentIndex < current.words.length - 1;

  bool get isFinished =>
      current.words.isNotEmpty &&
      current.results.length >= current.words.length &&
      current.currentIndex >= current.words.length - 1;

  int get totalCount => current.words.length;

  int get correctCount => current.results.where((r) => r.isCorrect).length;

  // ── User Actions ───────────────────────────────────────────

  /// Submit the current input for checking.
  void submit() {
    if (current.showResult) return; // already submitted this word

    final input = current.currentInput;
    final word = currentWord;
    final isCorrect = SpellingChecker.check(input, word.english);
    final result = SpellingResult(
      word: word,
      userAnswer: input,
      isCorrect: isCorrect,
    );

    _updateState((s) => s.copyWith(
          results: [...s.results, result],
          showResult: true,
        ));
  }

  /// Skip the current word (marks as incorrect, no answer).
  void skip() {
    if (current.showResult) return;

    final result = SpellingResult(
      word: currentWord,
      userAnswer: '',
      isCorrect: false,
      skipped: true,
    );

    _updateState((s) => s.copyWith(
          results: [...s.results, result],
          showResult: true,
        ));
  }

  /// Move to the next word.
  void nextWord() {
    if (!hasNext) return;

    _updateState((s) => s.copyWith(
          currentIndex: s.currentIndex + 1,
          currentInput: '',
          showResult: false,
          isPlaying: false,
        ));
  }

  /// Move to the previous word.
  void prevWord() {
    if (!hasPrev) return;

    _updateState((s) => s.copyWith(
          currentIndex: s.currentIndex - 1,
          currentInput: '',
          showResult: false,
          isPlaying: false,
        ));
  }

  /// Update the current text-field input.
  void updateInput(String value) {
    _updateState((s) => s.copyWith(currentInput: value));
  }

  /// Mark audio playback as started/stopped.
  void setPlaying(bool playing) {
    _updateState((s) => s.copyWith(isPlaying: playing));
  }

  /// Fetch TTS audio for the current word.
  Future<Uint8List> fetchAudio() async {
    final audioService = ref.read(audioServiceProvider);
    return audioService.fetchAudio(currentWord.english);
  }

  // ── Internal ───────────────────────────────────────────────

  void _updateState(SpellingState Function(SpellingState) updater) {
    final current = state.requireValue;
    state = AsyncData(updater(current));
  }
}

/// Immutable state for a spelling session.
///
/// All fields are final — mutations produce a new instance via [copyWith].
class SpellingState {
  const SpellingState({
    required this.words,
    required this.currentIndex,
    required this.results,
    required this.currentInput,
    required this.isPlaying,
    required this.showResult,
  });

  final List<domain.Word> words;
  final int currentIndex;
  final List<SpellingResult> results;
  final String currentInput;
  final bool isPlaying;
  final bool showResult;

  /// The result for the current word, if already submitted.
  SpellingResult? get currentResult {
    if (results.length > currentIndex) {
      return results[currentIndex];
    }
    return null;
  }

  SpellingState copyWith({
    List<domain.Word>? words,
    int? currentIndex,
    List<SpellingResult>? results,
    String? currentInput,
    bool? isPlaying,
    bool? showResult,
  }) {
    return SpellingState(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      results: results ?? this.results,
      currentInput: currentInput ?? this.currentInput,
      isPlaying: isPlaying ?? this.isPlaying,
      showResult: showResult ?? this.showResult,
    );
  }
}

/// Provider for the spelling session.
final spellingNotifierProvider =
    AsyncNotifierProvider<SpellingNotifier, SpellingState>(
  SpellingNotifier.new,
);
