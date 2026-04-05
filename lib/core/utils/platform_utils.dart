import 'dart:io';

import 'package:flutter/foundation.dart';

/// Utility for detecting the current platform and form factor.
abstract final class PlatformUtils {
  /// Whether running on Android TV (heuristic-based).
  static bool get isAndroidTV {
    if (!Platform.isAndroid) return false;
    // In production, use `device_info_plus` to check `systemFeatures`
    // for `android.software.leanback` and `android.hardware.type.television`.
    // For now, returns false—set to true for TV testing.
    return false;
  }

  static bool get isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool get isDesktop =>
      !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static bool get isTV => isAndroidTV;

  static bool get isWeb => kIsWeb;

  /// Returns the appropriate edge padding for the current platform.
  static double get screenPadding {
    if (isTV) return 48;
    if (isDesktop) return 32;
    return 16;
  }

  /// Grid cross-axis count based on platform/width.
  static int gridColumns(double screenWidth) {
    if (isTV) return 5;
    if (screenWidth >= 1200) return 5;
    if (screenWidth >= 900) return 4;
    if (screenWidth >= 600) return 3;
    return 2;
  }

  /// Card aspect ratio tuned per platform.
  static double get cardAspectRatio {
    if (isTV) return 0.75;
    if (isDesktop) return 0.8;
    return 0.85;
  }
}
