import 'package:flutter/material.dart';

/// Dark Luxe Broadcast — Motion Tokens
///
/// Consistent animation durations and curves for
/// premium, smooth motion across the app.
abstract final class AppMotion {
  // ── Durations ─────────────────────────────────────────────────
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration dramatic = Duration(milliseconds: 600);
  static const Duration splash = Duration(milliseconds: 1500);

  // ── Stagger Delays ────────────────────────────────────────────
  static const Duration staggerSmall = Duration(milliseconds: 50);
  static const Duration staggerMedium = Duration(milliseconds: 80);
  static const Duration staggerLarge = Duration(milliseconds: 120);

  // ── Curves ────────────────────────────────────────────────────
  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasis = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;
  static const Curve bounce = Curves.bounceOut;

  // TV-optimized (slightly slower for readability on big screen)
  static const Duration tvFast = Duration(milliseconds: 250);
  static const Duration tvNormal = Duration(milliseconds: 400);
  static const Duration tvSlow = Duration(milliseconds: 600);
}
