import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Resolved, fully-inverting tonal palette for the premium "Obsidian & Gold"
/// chrome. Construct from the active brightness — every surface, border, grid
/// line and text label flips atomically between light and dark.
///
/// Shared by [AppShell] and the feature view layers (POS, Floor, …) so the
/// entire app speaks one tonal language.
class AppTones {
  AppTones(this.isDark)
      : canvas = isDark ? AppColors.primary : AppColors.primaryLight,
        sidebar = isDark ? const Color(0xFF111C30) : Colors.white,
        surface = isDark ? AppColors.surface : AppColors.surfaceLight,
        surfaceAlt =
            isDark ? const Color(0xFF243349) : const Color(0xFFF1F5F9),
        border = isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        gridLine = isDark ? Colors.white10 : const Color(0xFFEDF1F6),
        textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight,
        textSecondary = isDark ? Colors.white70 : AppColors.textSecondaryLight,
        textMuted = isDark ? Colors.white38 : const Color(0xFF94A3B8),
        shadow = isDark
            ? Colors.black.withValues(alpha: 0.40)
            : Colors.black.withValues(alpha: 0.06);

  final bool isDark;
  final Color canvas;
  final Color sidebar;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color gridLine;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color shadow;

  /// The signature accent — held constant across both modes by design intent.
  static const Color gold = AppColors.accent;

  // --- Fixed dark navigation rail (CloudPOS Pro: dark sidebar, light content).
  // These stay dark in BOTH light and dark themes so the sidebar always reads
  // as the dark chrome from the reference design.
  static const Color navBg = Color(0xFF12121C);
  static const Color navAlt = Color(0xFF1E1E2C);
  static const Color navText = Color(0xFFECECF4);
  static const Color navMuted = Color(0xFF8B8BA6);
  static const Color navBorder = Color(0x14FFFFFF);
}
