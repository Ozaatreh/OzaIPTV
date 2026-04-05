import 'package:flutter/material.dart';

/// Convenience extensions on BuildContext for common operations.
extension BuildContextX on BuildContext {
  // ── Theme shortcuts ────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // ── Media query shortcuts ──────────────────────────────────
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get viewPadding => mediaQuery.viewPadding;
  EdgeInsets get viewInsets => mediaQuery.viewInsets;
  Orientation get orientation => mediaQuery.orientation;

  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isNarrow => screenWidth < 600;
  bool get isMedium => screenWidth >= 600 && screenWidth < 900;
  bool get isWide => screenWidth >= 900;
  bool get isExtraWide => screenWidth >= 1200;

  // ── Snackbar shortcut ─────────────────────────────────────
  void showSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }
}

/// Duration formatting extension.
extension DurationX on Duration {
  /// Format as "1h 23m" or "5m 30s".
  String get formatted {
    final h = inHours;
    final m = inMinutes.remainder(60);
    final s = inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  /// Format as "01:23:45" or "23:45".
  String get timestamp {
    final h = inHours;
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$m:$s';
    return '$m:$s';
  }
}
