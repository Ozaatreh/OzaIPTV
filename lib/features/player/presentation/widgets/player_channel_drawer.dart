import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/spacing.dart';
import '../../../../domain/entities/channel.dart';

/// A slide-up drawer inside the player for quick channel switching.
class PlayerChannelDrawer extends ConsumerWidget {
  const PlayerChannelDrawer({
    required this.currentChannelId,
    required this.onChannelSelected,
    required this.onClose,
    super.key,
  });

  final String currentChannelId;
  final ValueChanged<Channel> onChannelSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsProvider);

    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Handle bar + close
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Text(
                  'Channels',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white60,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.08),
          ),

          // Channel list
          Expanded(
            child: channelsAsync.when(
              data: (channels) => ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                ),
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  final isCurrent = channel.id == currentChannelId;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isCurrent
                          ? null
                          : () => onChannelSelected(channel),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                          vertical: AppSpacing.sm + 2,
                        ),
                        decoration: isCurrent
                            ? BoxDecoration(
                                color: AppColors.accentGold
                                    .withValues(alpha: 0.1),
                                border: Border(
                                  left: BorderSide(
                                    color: AppColors.accentGold,
                                    width: 3,
                                  ),
                                ),
                              )
                            : null,
                        child: Row(
                          children: [
                            // Channel number
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isCurrent
                                      ? AppColors.accentGold
                                      : Colors.white38,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Channel icon
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.live_tv_rounded,
                                size: 16,
                                color: isCurrent
                                    ? AppColors.accentGold
                                    : Colors.white38,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Channel name
                            Expanded(
                              child: Text(
                                channel.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCurrent
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isCurrent
                                      ? AppColors.accentGold
                                      : Colors.white70,
                                ),
                              ),
                            ),

                            // Playing indicator
                            if (isCurrent)
                              const _PlayingIndicator(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentGold,
                  strokeWidth: 2,
                ),
              ),
              error: (_, __) => const Center(
                child: Text(
                  'Failed to load channels',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayingIndicator extends StatefulWidget {
  const _PlayingIndicator();

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return ListenableBuilder(
    listenable: _controller,
    builder: (_, __) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final delay = i * 0.15;
        final value = ((_controller.value + delay) % 1.0);
        return Container(
          width: 3,
          height: 8 + (value * 8),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: AppColors.accentGold,
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      }),
    ),
  );
}
}

class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    required super.listenable,
    required this.builder,
    super.key,
  });
  final Widget Function(BuildContext, Widget?) builder;

  @override
  Widget build(BuildContext context) => builder(context, null);
}
