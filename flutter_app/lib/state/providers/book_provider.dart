import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/book.dart' as domain;
import '../../domain/models/unit.dart' as domain;
import '../../repositories/auth_repository.dart';
import '../../repositories/unit_repository.dart';
import 'auth_provider.dart';

/// The list of all available word books.
final bookListProvider = FutureProvider<List<domain.Book>>((ref) async {
  final repo = AuthRepository();
  return repo.getBooks();
});

/// The currently selected book schema.
///
/// On first read, falls back to the user's [currentBook]; if that is
/// null, defaults to the first available book.
final currentBookProvider =
    AsyncNotifierProvider<CurrentBookNotifier, domain.Book?>(
  CurrentBookNotifier.new,
);

class CurrentBookNotifier extends AsyncNotifier<domain.Book?> {
  @override
  Future<domain.Book?> build() async {
    final user = ref.watch(currentUserProvider);
    final books = await ref.watch(bookListProvider.future);

    if (books.isEmpty) return null;

    // Prefer the user's already-selected book.
    if (user?.currentBook != null) {
      final match = books.where((b) => b.schema == user!.currentBook).firstOrNull;
      if (match != null) return match;
    }

    return books.first;
  }

  /// Switch to a different book and persist on the backend.
  Future<void> selectBook(domain.Book book) async {
    final repo = AuthRepository();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.switchBook(book.schema);
      return book;
    });
  }
}

/// Units for the currently selected book.
final unitListProvider = FutureProvider<List<domain.Unit>>((ref) async {
  final currentBook = ref.watch(currentBookProvider).valueOrNull;
  if (currentBook == null) return [];

  final repo = UnitRepository();
  return repo.getUnits(bookSchema: currentBook.schema);
});
