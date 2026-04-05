/// Dark Luxe Broadcast — Spacing Scale
///
/// Consistent spacing tokens used across the entire app.
/// Based on a 4px base grid with contextual multipliers.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;

  // Screen edge padding
  static const double screenPaddingMobile = 16;
  static const double screenPaddingTablet = 24;
  static const double screenPaddingDesktop = 32;
  static const double screenPaddingTV = 48;

  // Section spacing
  static const double sectionGap = 28;
  static const double sectionGapLarge = 40;

  // Card grid spacing
  static const double cardGapSmall = 10;
  static const double cardGapMedium = 14;
  static const double cardGapLarge = 18;
}

/// Radius Scale
abstract final class AppRadius {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double base = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double round = 999;

  // Component-specific
  static const double card = 14;
  static const double button = 10;
  static const double chip = 20;
  static const double dialog = 20;
  static const double searchBar = 14;
  static const double thumbnail = 10;
  static const double avatar = 999;
}

/// Shadow Definitions
abstract final class AppShadows {
  static const List<BoxShadowData> cardShadow = [
    BoxShadowData(0, 4, 16, 0, 0x1A000000),
    BoxShadowData(0, 1, 4, 0, 0x33000000),
  ];

  static const List<BoxShadowData> elevatedShadow = [
    BoxShadowData(0, 8, 32, -4, 0x33000000),
    BoxShadowData(0, 2, 8, 0, 0x40000000),
  ];

  static const List<BoxShadowData> glowGold = [
    BoxShadowData(0, 0, 20, 0, 0x33D4A843),
  ];

  static const List<BoxShadowData> glowBlue = [
    BoxShadowData(0, 0, 20, 0, 0x334A9EFF),
  ];

  static const List<BoxShadowData> focusRing = [
    BoxShadowData(0, 0, 0, 3, 0x664A9EFF),
  ];
}

/// Helper class for shadow data (avoids importing flutter/material in tokens)
class BoxShadowData {
  const BoxShadowData(this.dx, this.dy, this.blur, this.spread, this.color);

  final double dx;
  final double dy;
  final double blur;
  final double spread;
  final int color;
}
