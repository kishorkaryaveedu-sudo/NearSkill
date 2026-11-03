import 'package:flutter/material.dart';

/// Stitch "Hyper-Local Trust" design system tokens — exact values from project 12010430252329760492
class AppColors {
  AppColors._();

  // ── Primary: Deep Teal ────────────────────────────────────────
  static const Color primary = Color(0xFF00685F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF008378);
  static const Color onPrimaryContainer = Color(0xFFF4FFFC);
  static const Color primaryFixed = Color(0xFF89F5E7);
  static const Color primaryFixedDim = Color(0xFF6BD8CB);
  static const Color onPrimaryFixed = Color(0xFF00201D);
  static const Color onPrimaryFixedVariant = Color(0xFF005049);
  static const Color inversePrimary = Color(0xFF6BD8CB);

  // ── Secondary: Amber ──────────────────────────────────────────
  static const Color secondary = Color(0xFF855300);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFEA619);
  static const Color onSecondaryContainer = Color(0xFF684000);
  static const Color secondaryFixed = Color(0xFFFFDDB8);
  static const Color secondaryFixedDim = Color(0xFFFFB95F);
  static const Color onSecondaryFixed = Color(0xFF2A1700);
  static const Color onSecondaryFixedVariant = Color(0xFF653E00);

  // ── Tertiary: Terracotta ──────────────────────────────────────
  static const Color tertiary = Color(0xFF924628);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB05E3D);
  static const Color onTertiaryContainer = Color(0xFFFFFBFF);
  static const Color tertiaryFixed = Color(0xFFFFDBCE);
  static const Color tertiaryFixedDim = Color(0xFFFFB59A);
  static const Color onTertiaryFixed = Color(0xFF370E00);
  static const Color onTertiaryFixedVariant = Color(0xFF773215);

  // ── Surfaces ──────────────────────────────────────────────────
  static const Color surface = Color(0xFFF9F9FF);
  static const Color background = Color(0xFFF9F9FF);
  static const Color surfaceBright = Color(0xFFF9F9FF);
  static const Color surfaceDim = Color(0xFFD3DAEA);
  static const Color surfaceVariant = Color(0xFFDCE2F3);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF0F3FF);
  static const Color surfaceContainer = Color(0xFFE7EEFE);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F8);
  static const Color surfaceContainerHighest = Color(0xFFDCE2F3);
  static const Color surfaceTint = Color(0xFF006A61);

  // ── On-Surface / Text ─────────────────────────────────────────
  static const Color onSurface = Color(0xFF151C27);
  static const Color onSurfaceVariant = Color(0xFF3D4947);
  static const Color onBackground = Color(0xFF151C27);
  static const Color inverseSurface = Color(0xFF2A313D);
  static const Color inverseOnSurface = Color(0xFFEBF1FF);

  // ── Outline ───────────────────────────────────────────────────
  static const Color outline = Color(0xFF6D7A77);
  static const Color outlineVariant = Color(0xFFBCC9C6);

  // ── Error ─────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Semantic aliases ──────────────────────────────────────────
  static const Color success = Color(0xFF00685F);    // primary teal for success
  static const Color warning = Color(0xFF855300);    // amber for warning
  static const Color info = Color(0xFF4A6FA5);       // blue for info
  static const Color star = Color(0xFFFEA619);       // amber for stars

  // ── Legacy aliases (backward compat) ─────────────────────────
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textMuted = outline;
  static const Color border = outlineVariant;
  static const Color borderLight = surfaceDim;
  static const Color shadow = Color(0x1A151C27);
  static const Color divider = surfaceContainer;
  static const Color accent = secondaryContainer;     // warm amber
  static const Color accentLight = secondaryFixed;
  static const Color accentDark = onSecondaryFixed;
  static const Color primaryLight = primaryFixedDim;
  static const Color primaryDark = onPrimaryFixedVariant;
  static const Color secondaryLight = secondaryFixedDim;

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6BD8CB), Color(0xFF00685F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFFFDDB8), Color(0xFF855300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
