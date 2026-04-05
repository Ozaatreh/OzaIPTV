import 'package:flutter/material.dart';

import '../../core/utils/platform_utils.dart';
import '../tokens/spacing.dart';

/// A responsive grid that adapts column count based on
/// screen width and platform (mobile, desktop, TV).
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    super.key,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = PlatformUtils.gridColumns(width);
    final aspectRatio = PlatformUtils.cardAspectRatio;
    final gap = PlatformUtils.isTV
        ? AppSpacing.cardGapLarge
        : AppSpacing.cardGapMedium;

    return GridView.builder(
      padding: padding ??
          EdgeInsets.all(PlatformUtils.screenPadding),
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: aspectRatio,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
