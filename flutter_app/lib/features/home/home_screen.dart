import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/book.dart' as domain;
import '../../domain/models/unit.dart' as domain;
import '../../features/flashcard/flashcard_screen.dart';
import '../../features/group/group_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/spelling/spelling_screen.dart';
import '../../state/providers/auth_provider.dart';
import '../../state/providers/book_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final booksAsync = ref.watch(bookListProvider);
    final currentBookAsync = ref.watch(currentBookProvider);
    final unitsAsync = ref.watch(unitListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.username ?? 'Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(unitListProvider);
          ref.invalidate(bookListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Greeting + Book ──────────────────────────
            Text(
              'Hello, ${user?.username ?? 'Learner'}',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              currentBookAsync.valueOrNull != null
                  ? '📖 ${currentBookAsync.valueOrNull!.name}'
                  : 'Loading…',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Book Selector ─────────────────────────────
            _BookSelector(
              books: booksAsync.valueOrNull ?? [],
              currentBook: currentBookAsync.valueOrNull,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Study Modes ───────────────────────────────
            Text(
              'Study Modes',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    icon: Icons.style_rounded,
                    label: 'Flashcard',
                    subtitle: 'Flip & Learn',
                    color: const Color(0xFF6366F1),
                    onTap: null, // needs unit selection
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ModeCard(
                    icon: Icons.edit_rounded,
                    label: 'Spelling',
                    subtitle: 'Write & Check',
                    color: const Color(0xFF22C55E),
                    onTap: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    icon: Icons.quiz_rounded,
                    label: 'Quiz',
                    subtitle: 'Multiple Choice',
                    color: const Color(0xFFF59E0B),
                    onTap: null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ModeCard(
                    icon: Icons.workspaces_rounded,
                    label: 'Group',
                    subtitle: 'Deep Memorize',
                    color: const Color(0xFFEF4444),
                    onTap: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Unit List ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Units',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (unitsAsync.valueOrNull != null)
                  Text(
                    '${unitsAsync.valueOrNull!.length} units',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (unitsAsync is AsyncLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (unitsAsync is AsyncError)
              _ErrorBox(
                message: 'Failed to load units',
                onRetry: () => ref.invalidate(unitListProvider),
              )
            else
              ...(unitsAsync.valueOrNull ?? []).map(
                (unit) => _UnitTile(
                  unit: unit,
                  bookSchema: currentBookAsync.valueOrNull?.schema,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ),
            const SizedBox(height: AppSpacing.xl),

            // ── History + Stats row ──────────────────────
            Row(
              children: [
                Expanded(
                  child: _NavCard(
                    icon: Icons.auto_graph_rounded,
                    label: 'Statistics',
                    color: colorScheme.primary,
                    onTap: () => context.go(AppRouter.statsPath),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NavCard(
                    icon: Icons.history,
                    label: 'History',
                    color: colorScheme.tertiary,
                    onTap: () => context.go(AppRouter.historyPath),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Mode Card
// ────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Nav Card (History / Stats)
// ────────────────────────────────────────────────────────────────

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Book Selector
// ────────────────────────────────────────────────────────────────

class _BookSelector extends ConsumerWidget {
  const _BookSelector({required this.books, required this.currentBook});
  final List<domain.Book> books;
  final domain.Book? currentBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (books.length < 2) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: books.map((book) {
        final selected = book.schema == currentBook?.schema;
        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(right: book == books.last ? 0 : AppSpacing.sm),
            child: ChoiceChip(
              label: Text(book.name),
              selected: selected,
              onSelected: (_) =>
                  ref.read(currentBookProvider.notifier).selectBook(book),
              showCheckmark: false,
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                color:
                    selected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Unit Tile — opens mode bottom sheet
// ────────────────────────────────────────────────────────────────

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.unit,
    this.bookSchema,
    required this.colorScheme,
    required this.textTheme,
  });

  final domain.Unit unit;
  final String? bookSchema;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  void _showModeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(unit.name,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text('${unit.wordCount} words',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.5))),
              const SizedBox(height: AppSpacing.xl),
              _ModeTile(
                icon: Icons.style_rounded,
                title: 'Flashcard',
                subtitle: 'Flip cards, learn visually',
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(AppRouter.flashcardPath,
                      extra: FlashcardParams(
                          unitId: unit.id,
                          unitName: unit.name,
                          bookSchema: bookSchema));
                },
              ),
              _ModeTile(
                icon: Icons.edit_rounded,
                title: 'Spelling',
                subtitle: 'Hear Chinese, type English',
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(AppRouter.spellingPath,
                      extra: SpellingParams(
                          unitId: unit.id,
                          unitName: unit.name,
                          bookSchema: bookSchema));
                },
              ),
              _ModeTile(
                icon: Icons.quiz_rounded,
                title: 'Quiz',
                subtitle: 'Multiple choice test',
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(AppRouter.quizPath,
                      extra: QuizParams(
                          unitId: unit.id,
                          unitName: unit.name,
                          bookSchema: bookSchema));
                },
              ),
              _ModeTile(
                icon: Icons.workspaces_rounded,
                title: 'Group Study',
                subtitle: 'Deep memorization with review',
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(AppRouter.groupPath,
                      extra: GroupParams(
                          unitId: unit.id,
                          unitName: unit.name,
                          bookSchema: bookSchema));
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: InkWell(
          onTap: () => _showModeSheet(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(Icons.menu_book_outlined,
                      color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unit.name,
                          style: textTheme.titleMedium
                              ?.copyWith(color: colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      Text('${unit.wordCount} words',
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Error
// ────────────────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(children: [
          Icon(Icons.cloud_off_rounded,
              size: 36, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      ),
    );
  }
}
