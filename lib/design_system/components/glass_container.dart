import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// A premium glassmorphism container with blur, subtle tint,
/// and border highlight. Use sparingly for overlays and modals.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    this.borderRadius = AppRadius.lg,
    this.blur = 16,
    this.opacity = 0.08,
    this.padding,
    this.border = true,
    super.key,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsets? padding;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.glassWhite.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border
                ? Border.all(color: AppColors.glassBorder, width: 0.5)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A glassmorphic dialog/modal container with centered content.
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    required this.child,
    this.width,
    this.maxWidth = 400,
    super.key,
  });

  final Widget child;
  final double? width;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GlassContainer(
          borderRadius: AppRadius.dialog,
          blur: 24,
          opacity: 0.12,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: child,
        ),
      ),
    );
  }
}
