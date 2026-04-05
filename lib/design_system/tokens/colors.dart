import 'package:flutter/material.dart';

/// Dark Luxe Broadcast — Color Tokens
///
/// A premium dark palette inspired by high-end streaming platforms.
/// Uses deep navy-blacks, rich accent golds, and electric blues
/// for a cinematic, broadcast-quality aesthetic.
abstract final class AppColors {
  // ── Background Layers ─────────────────────────────────────────
  static const Color backgroundPrimary = Color(0xFF0A0A0F);
  static const Color backgroundSecondary = Color(0xFF111118);
  static const Color backgroundTertiary = Color(0xFF181822);
  static const Color backgroundElevated = Color(0xFF1E1E2C);
  static const Color backgroundCard = Color(0xFF16161F);
  static const Color backgroundOverlay = Color(0xCC0A0A0F);

  // ── Surface ───────────────────────────────────────────────────
  static const Color surfacePrimary = Color(0xFF1A1A26);
  static const Color surfaceSecondary = Color(0xFF222233);
  static const Color surfaceHover = Color(0xFF2A2A3D);
  static const Color surfacePressed = Color(0xFF33334D);
  static const Color surfaceFocused = Color(0xFF2D2D44);

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textTertiary = Color(0xFF7A7A90);
  static const Color textDisabled = Color(0xFF4A4A5C);
  static const Color textOnAccent = Color(0xFF0A0A0F);

  // ── Accent — Gold ─────────────────────────────────────────────
  static const Color accentGold = Color(0xFFD4A843);
  static const Color accentGoldLight = Color(0xFFE8C96A);
  static const Color accentGoldDark = Color(0xFFAA8530);
  static const Color accentGoldSubtle = Color(0x1AD4A843);

  // ── Accent — Electric Blue ────────────────────────────────────
  static const Color accentBlue = Color(0xFF4A9EFF);
  static const Color accentBlueLight = Color(0xFF7BB8FF);
  static const Color accentBlueDark = Color(0xFF2B7DE0);
  static const Color accentBlueSubtle = Color(0x1A4A9EFF);

  // ── Accent — Purple ───────────────────────────────────────────
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPurpleLight = Color(0xFFA78BFA);
  static const Color accentPurpleSubtle = Color(0x1A8B5CF6);

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = Color(0xFF34D399);
  static const Color successSubtle = Color(0x1A34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningSubtle = Color(0x1AFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSubtle = Color(0x1AEF4444);
  static const Color info = Color(0xFF4A9EFF);
  static const Color infoSubtle = Color(0x1A4A9EFF);

  // ── Live Indicator ────────────────────────────────────────────
  static const Color liveRed = Color(0xFFFF3B3B);
  static const Color liveRedGlow = Color(0x40FF3B3B);

  // ── Border ────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFF2A2A3D);
  static const Color borderDefault = Color(0xFF3A3A50);
  static const Color borderFocused = Color(0xFF4A9EFF);
  static const Color borderAccent = Color(0xFFD4A843);

  // ── Glassmorphism ─────────────────────────────────────────────
  static const Color glassWhite = Color(0x0DFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundPrimary, Color(0xFF0D0D15)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A28), Color(0xFF14141E)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGold, Color(0xFFE8A020)],
  );

  static const LinearGradient playerOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xE60A0A0F)],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1, -0.3),
    end: Alignment(1, 0.3),
    colors: [
      Color(0xFF1A1A26),
      Color(0xFF252536),
      Color(0xFF1A1A26),
    ],
  );
}
