import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/quiz.dart' as domain;
import '../../domain/models/quiz_question.dart';
import '../../domain/models/word.dart' as domain;
import '../../models/quiz_session.dart' as dto;
import '../../repositories/quiz_repository.dart';
import '../../repositories/word_repository.dart';

/// Manages the full quiz lifecycle: load → answer → submit → result.
class QuizNotifier extends AsyncNotifier<QuizState> {
  @override
  Future<QuizState> build() async {
    return const QuizState.initial();
  }

  // ── State helpers ──────────────────────────────────────────

  QuizState get current => state.requireValue;
  QuizQuestion get currentQuestion =>
      current.questions[current.currentIndex];
  bool get isLastQuestion =>
      current.currentIndex >= current.questions.length - 1;

  // ── Initialisation ─────────────────────────────────────────

  /// Load words and generate quiz questions for the given unit.
  Future<void> loadQuiz({
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
      if (words.isEmpty) {
        throw Exception('No words in this unit');
      }
      final questions = QuizQuestionGenerator.generate(words);
      return QuizState(
        questions: questions,
        unitIds: [unitId],
        bookSchema: bookSchema,
        currentIndex: 0,
        selectedIndex: null,
        answers: [],
        isSubmitted: false,
        result: null,
        startedAt: DateTime.now(),
      );
    });
  }

  // ── Answer ─────────────────────────────────────────────────

  /// Select an option for the current question.
  /// Auto-advances to the next question after a brief delay.
  void selectAnswer(int optionIndex) {
    if (current.selectedIndex != null) return; // already answered
    if (current.isSubmitted) return;

    final question = currentQuestion;
    final isCorrect = question.isCorrect(optionIndex);

    final answer = domain.QuizAnswer(
      wordId: question.word.id,
      chinese: question.word.chinese,
      english: question.word.english,
      userAnswer: question.options[optionIndex],
      isCorrect: isCorrect,
    );

    _updateState((s) => s.copyWith(
          selectedIndex: optionIndex,
          answers: [...s.answers, answer],
        ));
  }

  /// Advance to the next question or complete the quiz.
  void advance() {
    if (current.selectedIndex == null) return; // must answer first

    if (isLastQuestion) {
      _complete();
    } else {
      _updateState((s) => s.copyWith(
            currentIndex: s.currentIndex + 1,
            selectedIndex: null,
          ));
    }
  }

  /// Compute final result but do NOT submit to backend yet.
  void _complete() {
    final correct = current.answers.where((a) => a.isCorrect).length;
    final total = current.answers.length;
    final scorePct =
        total > 0 ? (correct / total * 100).roundToDouble() : 0.0;

    final result = domain.QuizResult(
      sessionId: 0, // placeholder — real ID comes from submit
      totalCount: total,
      correctCount: correct,
      scorePct: scorePct,
    );

    _updateState((s) => s.copyWith(result: result));
  }

  /// Submit the completed quiz to the backend.
  Future<void> submit() async {
    if (current.result == null) return;
    if (current.isSubmitted) return;

    _updateState((s) => s.copyWith(isSubmitting: true));

    final repo = QuizRepository();
    final durationSec = DateTime.now().difference(current.startedAt!).inSeconds;

    final dtoAnswers = current.answers
        .map((a) => dto.AnswerSubmit(
              wordId: a.wordId,
              userAnswer: a.userAnswer,
              isCorrect: a.isCorrect,
            ))
        .toList(growable: false);

    try {
      final submitResult = await repo.submitQuiz(
        unitIds: current.unitIds,
        answers: dtoAnswers,
        durationSeconds: durationSec,
        bookSchema: current.bookSchema,
      );
      _updateState(
        (s) => s.copyWith(
          isSubmitted: true,
          isSubmitting: false,
          result: submitResult,
        ),
      );
    } on Exception {
      _updateState((s) => s.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  /// Reset to start a new quiz.
  void reset() {
    state = const AsyncData(QuizState.initial());
  }

  // ── Internal ───────────────────────────────────────────────

  void _updateState(QuizState Function(QuizState) updater) {
    state = AsyncData(updater(current));
  }
}

/// Immutable state for a quiz session.
class QuizState {
  const QuizState({
    required this.questions,
    required this.unitIds,
    this.bookSchema,
    required this.currentIndex,
    required this.selectedIndex,
    required this.answers,
    required this.isSubmitted,
    required this.result,
    this.isSubmitting = false,
    this.startedAt,
  });

  /// Create an empty initial state.
  const QuizState.initial()
      : questions = const [],
        unitIds = const [],
        bookSchema = null,
        currentIndex = 0,
        selectedIndex = null,
        answers = const [],
        isSubmitted = false,
        result = null,
        isSubmitting = false,
        startedAt = null;

  final List<QuizQuestion> questions;
  final List<int> unitIds;
  final String? bookSchema;
  final int currentIndex;
  final int? selectedIndex;
  final List<domain.QuizAnswer> answers;
  final bool isSubmitted;
  final domain.QuizResult? result;
  final bool isSubmitting;
  final DateTime? startedAt;

  bool get isComplete => result != null;
  bool get hasQuestions => questions.isNotEmpty;

  int get correctCount => answers.where((a) => a.isCorrect).length;
  int get wrongCount => answers.where((a) => !a.isCorrect).length;
  int get answeredCount => answers.length;

  QuizState copyWith({
    List<QuizQuestion>? questions,
    List<int>? unitIds,
    String? bookSchema,
    int? currentIndex,
    int? selectedIndex,
    List<domain.QuizAnswer>? answers,
    bool? isSubmitted,
    domain.QuizResult? result,
    bool? isSubmitting,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      unitIds: unitIds ?? this.unitIds,
      bookSchema: bookSchema ?? this.bookSchema,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      answers: answers ?? this.answers,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      result: result ?? this.result,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      startedAt: startedAt,
    );
  }
}

/// Provider for the quiz session.
final quizNotifierProvider =
    AsyncNotifierProvider<QuizNotifier, QuizState>(
  QuizNotifier.new,
);
