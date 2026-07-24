import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_client.dart';
import 'core/error/crash_handler.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global crash handler — catches unhandled errors.
  CrashHandler.setup();

  // Initialize the API client singleton early.
  ApiClient();

  runApp(
    const ProviderScope(
      child: VocabularyMemorizationApp(),
    ),
  );
}

class VocabularyMemorizationApp extends ConsumerStatefulWidget {
  const VocabularyMemorizationApp({super.key});

  @override
  ConsumerState<VocabularyMemorizationApp> createState() =>
      _VocabularyMemorizationAppState();
}

class _VocabularyMemorizationAppState
    extends ConsumerState<VocabularyMemorizationApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create the router once, with a Ref that's valid for the lifetime
    // of this widget's state.
    _router = AppRouter.createRouter(ref);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vocabulary Memorization',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
