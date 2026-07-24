import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../state/providers/auth_provider.dart';

/// Login screen with two tabs: Student Login and Teacher Login.
///
/// Auth state is managed by [authNotifierProvider]. Form validation
/// is done locally before calling the provider.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _studentUsernameCtrl = TextEditingController();
  final _studentPasswordCtrl = TextEditingController();
  final _teacherUsernameCtrl = TextEditingController();
  final _teacherPasswordCtrl = TextEditingController();

  final _studentFormKey = GlobalKey<FormState>();
  final _teacherFormKey = GlobalKey<FormState>();

  bool _studentObscure = true;
  bool _teacherObscure = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentUsernameCtrl.dispose();
    _studentPasswordCtrl.dispose();
    _teacherUsernameCtrl.dispose();
    _teacherPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Student Login ──────────────────────────────────────────

  Future<void> _submitStudent() async {
    if (!_studentFormKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(
          username: _studentUsernameCtrl.text.trim(),
          password: _studentPasswordCtrl.text,
        );
  }

  // ── Teacher Login ──────────────────────────────────────────

  Future<void> _submitTeacher() async {
    if (!_teacherFormKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).teacherLogin(
          username: _teacherUsernameCtrl.text.trim(),
          password: _teacherPasswordCtrl.text,
        );
  }

  // ── Register ───────────────────────────────────────────────

  Future<void> _navigateToRegister() async {
    // Navigate to register page (built in a future milestone).
    // For now, show a modal or snackbar.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Register coming in next milestone')),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;
    final error = authState is AsyncError ? authState.error.toString() : null;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 48),
                // App branding
                Icon(
                  Icons.menu_book_rounded,
                  size: 56,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Vocabulary Memorization',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),

                // Error banner
                if (error != null) ...[
                  _ErrorBanner(message: _cleanError(error)),
                  const SizedBox(height: 16),
                ],

                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: colorScheme.onPrimary,
                    unselectedLabelColor: colorScheme.onSurface,
                    dividerHeight: 0,
                    tabs: const [
                      Tab(text: 'Student'),
                      Tab(text: 'Teacher'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tab content
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _StudentForm(
                        formKey: _studentFormKey,
                        usernameCtrl: _studentUsernameCtrl,
                        passwordCtrl: _studentPasswordCtrl,
                        obscure: _studentObscure,
                        isLoading: isLoading,
                        onToggleObscure: () =>
                            setState(() => _studentObscure = !_studentObscure),
                        onSubmit: _submitStudent,
                        onRegister: _navigateToRegister,
                        colorScheme: colorScheme,
                      ),
                      _TeacherForm(
                        formKey: _teacherFormKey,
                        usernameCtrl: _teacherUsernameCtrl,
                        passwordCtrl: _teacherPasswordCtrl,
                        obscure: _teacherObscure,
                        isLoading: isLoading,
                        onToggleObscure: () =>
                            setState(() => _teacherObscure = !_teacherObscure),
                        onSubmit: _submitTeacher,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Strip exception class name prefix for display.
  String _cleanError(String raw) {
    final idx = raw.lastIndexOf(':');
    return idx >= 0 ? raw.substring(idx + 1).trim() : raw;
  }
}

// ────────────────────────────────────────────────────────────────
// Error Banner
// ────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Student Login Form
// ────────────────────────────────────────────────────────────────

class _StudentForm extends StatelessWidget {
  const _StudentForm({
    required this.formKey,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onRegister,
    required this.colorScheme,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onRegister;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter your username' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordCtrl,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter your password' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Log in'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRegister,
            child: const Text('Create an account'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Teacher Login Form
// ────────────────────────────────────────────────────────────────

class _TeacherForm extends StatelessWidget {
  const _TeacherForm({
    required this.formKey,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.colorScheme,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'Teacher ID',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter teacher ID' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordCtrl,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter password' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Teacher Log in'),
            ),
          ),
        ],
      ),
    );
  }
}
