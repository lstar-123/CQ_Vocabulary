import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/pagination.dart' as domain;
import '../../domain/models/quiz.dart' as domain;
import '../../repositories/history_repository.dart';

/// Manages quiz history retrieval with pagination.
class HistoryNotifier extends AsyncNotifier<HistoryState> {
  @override
  Future<HistoryState> build() async {
    return _loadPage(1);
  }

  // ── Public ─────────────────────────────────────────────────

  /// Load a specific page.
  Future<void> loadPage(int page) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadPage(page));
  }

  /// Refresh the first page (e.g., after pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadPage(1));
  }

  // ── Internal ───────────────────────────────────────────────

  Future<HistoryState> _loadPage(int page) async {
    final repo = HistoryRepository();
    final result = await repo.getHistory(page: page);
    return HistoryState(
      items: result.items,
      total: result.total,
      page: result.page,
      perPage: result.perPage,
      totalPages: result.totalPages,
    );
  }
}

/// Immutable history state.
class HistoryState {
  const HistoryState({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  final List<domain.QuizSession> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  bool get hasMore => page < totalPages;
  bool get isEmpty => items.isEmpty;

  HistoryState copyWith({
    List<domain.QuizSession>? items,
    int? total,
    int? page,
    int? perPage,
    int? totalPages,
  }) {
    return HistoryState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

final historyNotifierProvider =
    AsyncNotifierProvider<HistoryNotifier, HistoryState>(
  HistoryNotifier.new,
);
