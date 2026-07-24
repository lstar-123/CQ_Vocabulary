import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/spelling.dart';
import '../../domain/models/word.dart' as domain;
import '../../repositories/word_repository.dart';

// ── Phases ───────────────────────────────────────────────────

enum GroupPhase {
  loading,
  memory, // card flip + Remember / Forgot
  spelling, // type English for Chinese
  wrongReview, // re-test wrong words
  summary, // stats + submit
}

// ── State ────────────────────────────────────────────────────

class GroupLearningState {
  const GroupLearningState({
    required this.allWords,
    required this.groups,
    required this.currentGroupIndex,
    required this.currentWordIndex,
    required this.phase,
    required this.wrongWords,
    required this.groupResults,
    required this.rememberedCount,
    this.startedAt,
    this.finishedAt,
  });

  static const empty = GroupLearningState(
    allWords: [],
    groups: [],
    currentGroupIndex: 0,
    currentWordIndex: 0,
    phase: GroupPhase.loading,
    wrongWords: [],
    groupResults: {},
    rememberedCount: 0,
  );

  final List<domain.Word> allWords;
  final List<List<domain.Word>> groups;
  final int currentGroupIndex;
  final int currentWordIndex;
  final GroupPhase phase;
  final List<domain.Word> wrongWords;
  final Map<int, List<bool>> groupResults; // groupIdx → list of isCorrect per word
  final int rememberedCount;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  // ── Derived ────────────────────────────────────

  List<domain.Word> get currentGroup =>
      groups.isNotEmpty && currentGroupIndex < groups.length
          ? groups[currentGroupIndex]
          : [];

  domain.Word? get currentWord =>
      currentGroup.isNotEmpty && currentWordIndex < currentGroup.length
          ? currentGroup[currentWordIndex]
          : null;

  int get totalGroups => groups.length;

  int get totalWords => allWords.length;

  int get totalWrong => wrongWords.length;

  int get totalCorrect => rememberedCount;

  double get accuracy =>
      totalWords > 0 ? rememberedCount / totalWords : 0;

  String get progressLabel =>
      'Group ${currentGroupIndex + 1} / $totalGroups';

  double get groupProgress =>
      currentGroup.isNotEmpty
          ? (currentWordIndex) / currentGroup.length
          : 0;

  GroupLearningState copyWith({
    List<domain.Word>? allWords,
    List<List<domain.Word>>? groups,
    int? currentGroupIndex,
    int? currentWordIndex,
    GroupPhase? phase,
    List<domain.Word>? wrongWords,
    Map<int, List<bool>>? groupResults,
    int? rememberedCount,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return GroupLearningState(
      allWords: allWords ?? this.allWords,
      groups: groups ?? this.groups,
      currentGroupIndex: currentGroupIndex ?? this.currentGroupIndex,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      phase: phase ?? this.phase,
      wrongWords: wrongWords ?? this.wrongWords,
      groupResults: groupResults ?? this.groupResults,
      rememberedCount: rememberedCount ?? this.rememberedCount,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────

class GroupLearningNotifier extends AsyncNotifier<GroupLearningState> {
  static const int _groupSize = 5;

  @override
  Future<GroupLearningState> build() async {
    return GroupLearningState.empty;
  }

  // ── Init: load words + split into groups ───────────────────

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
      // Shuffle then split into groups.
      final shuffled = List<domain.Word>.from(words)..shuffle(Random());
      final groups = <List<domain.Word>>[];
      for (var i = 0; i < shuffled.length; i += _groupSize) {
        final end = (i + _groupSize).clamp(0, shuffled.length);
        groups.add(shuffled.sublist(i, end));
      }
      return GroupLearningState.empty.copyWith(
        allWords: shuffled,
        groups: groups,
        phase: GroupPhase.memory,
        startedAt: DateTime.now(),
      );
    });
  }

  // ── Memory phase ───────────────────────────────────────────

  /// Mark the current word as remembered.
  void markRemembered() {
    final current = state.requireValue;
    if (current.phase != GroupPhase.memory) return;
    if (current.currentWord == null) return;

    final newRemembered = current.rememberedCount + 1;
    _recordResult(true);
    _updateState(current.copyWith(rememberedCount: newRemembered));
    _advanceMemoryWord();
  }

  /// Mark the current word as forgotten (goes to wrong queue).
  void markForgot() {
    final current = state.requireValue;
    if (current.phase != GroupPhase.memory) return;
    if (current.currentWord == null) return;

    final newWrong = [...current.wrongWords, current.currentWord!];
    _recordResult(false);
    _updateState(current.copyWith(wrongWords: newWrong));
    _advanceMemoryWord();
  }

  void _recordResult(bool isCorrect) {
    final current = state.requireValue;
    final map = Map<int, List<bool>>.from(current.groupResults);
    final list = List<bool>.from(map[current.currentGroupIndex] ?? []);
    list.add(isCorrect);
    map[current.currentGroupIndex] = list;
    _updateState(current.copyWith(groupResults: map));
  }

  void _advanceMemoryWord() {
    final current = state.requireValue;
    final nextIdx = current.currentWordIndex + 1;

    if (nextIdx < current.currentGroup.length) {
      _updateState(current.copyWith(currentWordIndex: nextIdx));
    } else {
      // Group memory finished → start spelling for this group.
      _updateState(current.copyWith(
        currentWordIndex: 0,
        phase: GroupPhase.spelling,
      ));
    }
  }

  // ── Spelling phase ─────────────────────────────────────────

  /// Submit spelling answer for the current word.
  /// Returns: whether the answer was correct.
  bool submitSpelling(String userAnswer) {
    final current = state.requireValue;
    if (current.phase != GroupPhase.spelling) return false;
    if (current.currentWord == null) return false;

    final isCorrect =
        SpellingChecker.check(userAnswer, current.currentWord!.english);
    if (!isCorrect) {
      final exists = current.wrongWords
          .any((w) => w.id == current.currentWord!.id);
      if (!exists) {
        _updateState(current.copyWith(
          wrongWords: [...current.wrongWords, current.currentWord!],
        ));
      }
    }
    return isCorrect;
  }

  /// Advance to next word in spelling.
  void advanceSpelling() {
    final current = state.requireValue;
    final nextIdx = current.currentWordIndex + 1;

    if (nextIdx < current.currentGroup.length) {
      _updateState(current.copyWith(currentWordIndex: nextIdx));
    } else {
      // Group spelling done → next group or wrong review or summary.
      _advanceGroup();
    }
  }

  // ── Group advance ──────────────────────────────────────────

  void _advanceGroup() {
    final current = state.requireValue;
    final nextGroup = current.currentGroupIndex + 1;

    if (nextGroup < current.groups.length) {
      _updateState(current.copyWith(
        currentGroupIndex: nextGroup,
        currentWordIndex: 0,
        phase: GroupPhase.memory,
      ));
    } else {
      // All groups done.
      if (current.wrongWords.isNotEmpty) {
        _updateState(current.copyWith(
          currentWordIndex: 0,
          phase: GroupPhase.wrongReview,
        ));
      } else {
        _finish(current);
      }
    }
  }

  // ── Wrong Review phase ─────────────────────────────────────

  /// Handle a wrong-review word: mark as corrected or still wrong.
  void markWrongCorrect() {
    final current = state.requireValue;
    if (current.phase != GroupPhase.wrongReview) return;
    final next = current.currentWordIndex + 1;
    if (next < current.wrongWords.length) {
      _updateState(current.copyWith(currentWordIndex: next));
    } else {
      _finish(current);
    }
  }

  void markWrongStillWrong() {
    final current = state.requireValue;
    if (current.phase != GroupPhase.wrongReview) return;
    final next = current.currentWordIndex + 1;
    if (next < current.wrongWords.length) {
      _updateState(current.copyWith(currentWordIndex: next));
    } else {
      _finish(current);
    }
  }

  // ── Summary ────────────────────────────────────────────────

  void _finish(GroupLearningState current) {
    _updateState(current.copyWith(
      phase: GroupPhase.summary,
      finishedAt: DateTime.now(),
    ));
  }

  /// Reset for a new session.
  void reset() {
    state = const AsyncData(GroupLearningState.empty);
  }

  // ── Internal ───────────────────────────────────────────────

  void _updateState(GroupLearningState val) {
    state = AsyncData(val);
  }
}

final groupLearningNotifierProvider = AsyncNotifierProvider<
    GroupLearningNotifier, GroupLearningState>(
  GroupLearningNotifier.new,
);
