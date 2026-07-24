import 'package:flutter/material.dart';

/// Semantic color tokens consumed by [AppTheme].
///
/// Every color used in the UI must reference a token from this class.
/// Never use [Colors.blue] or hardcoded hex values directly in widgets.
///
/// Inspired by Apple Human Interface / Notion / Linear:
/// - Neutral-first palette with restrained accent use
/// - High-contrast text on low-contrast surfaces
/// - Consistent light and dark variants
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF3B82F6); // Blue-500
  static const Color onPrimary = Colors.white;

  // ── Semantic ───────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E); // Green-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color info = Color(0xFF6366F1); // Indigo-500

  // ── Neutral (Light) ────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF8FAFC); // Slate-50
  static const Color cardLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0); // Slate-200
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate-900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate-500
  static const Color textTertiaryLight = Color(0xFF94A3B8); // Slate-400

  // ── Neutral (Dark) ─────────────────────────────────────────
  static const Color surfaceDark = Color(0xFF0F172A); // Slate-900
  static const Color cardDark = Color(0xFF1E293B); // Slate-800
  static const Color borderDark = Color(0xFF334155); // Slate-700
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // Slate-100
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate-400
  static const Color textTertiaryDark = Color(0xFF64748B); // Slate-500
}
