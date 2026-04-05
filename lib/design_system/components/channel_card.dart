import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ozaiptv/design_system/tokens/colors.dart';
import 'package:ozaiptv/design_system/tokens/spacing.dart';



/// A premium channel card used in grids and lists.
/// Supports focus states for TV D-pad navigation.
class ChannelCard extends StatefulWidget {
  const ChannelCard({
    required this.name,
    required this.onTap,
    this.logoUrl,
    this.categoryName,
    this.currentProgram,
    this.isLive = false,
    this.isFavorite = false,
    this.onLongPress,
    super.key,
  });

  final String name;
  final String? logoUrl;
  final String? categoryName;
  final String? currentProgram;
  final bool isLive;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: _isFocused
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: _isFocused
                  ? AppColors.accentGold
                  : AppColors.borderSubtle,
              width: _isFocused ? 2 : 0.5,
            ),
            boxShadow: _isFocused
                ? [
                    const BoxShadow(
                      color: Color(0x33D4A843),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail / Logo area
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Logo
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.card),
                      ),
                      child: widget.logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.logoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.surfacePrimary,
                                child: const Center(
                                  child: Icon(
                                    Icons.live_tv_rounded,
                                    color: AppColors.textTertiary,
                                    size: 32,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.surfacePrimary,
                                child: const Center(
                                  child: Icon(
                                    Icons.live_tv_rounded,
                                    color: AppColors.textTertiary,
                                    size: 32,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.surfacePrimary,
                              child: Center(
                                child: Text(
                                  widget.name.isNotEmpty
                                      ? widget.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentGold,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    // Live badge
                    if (widget.isLive)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.liveRed,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.liveRedGlow,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),

                    // Favorite indicator
                    if (widget.isFavorite)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.favorite_rounded,
                          color: AppColors.accentGold,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),

              // Info area
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (widget.currentProgram != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.currentProgram!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ] else if (widget.categoryName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.categoryName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
