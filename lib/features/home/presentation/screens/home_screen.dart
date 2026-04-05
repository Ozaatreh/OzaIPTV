import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers.dart';
import '../../../../design_system/components/channel_card.dart';
import '../../../../design_system/components/loading_states.dart';
import '../../../../design_system/components/section_header.dart';
import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/spacing.dart';
import '../../../../domain/entities/channel.dart';
import '../../../../routing/route_names.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.backgroundPrimary,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: AppColors.accentGradient,
                  ),
                  child: const Icon(Icons.live_tv_rounded,
                      color: AppColors.textOnAccent, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('OzaIPTV',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'History',
                onPressed: () => context.push(RoutePaths.history),
              ),
              IconButton(
                icon: const Icon(Icons.newspaper_rounded),
                tooltip: 'Guide',
                onPressed: () => context.push(RoutePaths.epg),
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => context.goNamed(RouteNames.search),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Body
          channelsAsync.when(
            data: (channels) => SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.base),

                // Hero featured channel
                _HeroSection(channels: channels),
                const SizedBox(height: AppSpacing.sectionGap),

                // Quick actions row
                _QuickActions(),
                const SizedBox(height: AppSpacing.sectionGap),

                // Continue watching (from history)
                historyAsync.when(
                  data: (history) {
                    if (history.isEmpty) return const SizedBox.shrink();
                    final recentIds = history
                        .take(6)
                        .map((h) => h.channelId)
                        .toSet()
                        .toList();
                    final recentChannels = recentIds
                        .map((id) {
                          try {
                            return channels.firstWhere((c) => c.id == id);
                          } catch (_) {
                            return null;
                          }
                        })
                        .whereType<Channel>()
                        .toList();
                    if (recentChannels.isEmpty) return const SizedBox.shrink();
                    return _ChannelHorizontalSection(
                      title: 'Continue Watching',
                      channels: recentChannels,
                      actionLabel: 'History',
                      onAction: () => context.push(RoutePaths.history),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Category chips
                categoriesAsync.when(
                  data: (categories) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.base),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          return ActionChip(
                            label: Text(cat.name),
                            backgroundColor: AppColors.surfacePrimary,
                            side: const BorderSide(
                                color: AppColors.borderSubtle),
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () =>
                                context.goNamed(RouteNames.liveTv),
                          );
                        },
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // All channels grid
                SectionHeader(
                  title: 'All Channels',
                  subtitle: '${channels.length} live streams',
                  actionLabel: 'See All',
                  onActionTap: () => context.goNamed(RouteNames.liveTv),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildGrid(context, channels),
                const SizedBox(height: AppSpacing.huge),
              ]),
            ),
            loading: () => const SliverFillRemaining(
              child: Center(child: ChannelGridSkeleton()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: ErrorStateWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(channelsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Channel> channels) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        mainAxisSpacing: AppSpacing.cardGapMedium,
        crossAxisSpacing: AppSpacing.cardGapMedium,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return ChannelCard(
          name: channel.name,
          logoUrl: channel.logoUrl,
          isLive: channel.isLive,
          onTap: () => context.push('/player/${channel.id}'),
        );
      },
    );
  }
}

// ── Hero section ────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.channels});
  final List<Channel> channels;

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) return const SizedBox.shrink();
    final featured = channels.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: GestureDetector(
        onTap: () => context.push('/player/${featured.id}'),
        child: Container(
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: MediaQuery.of(context).size.height * 0.32,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A30), Color(0xFF0F0F1A)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderSubtle, width: 0.5),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppColors.accentGold.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  top: AppSpacing.xl,
                  bottom: MediaQuery.of(context).padding.bottom + AppSpacing.base,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.liveRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('LIVE NOW',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(height: 12),
                    Text(featured.name,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      featured.description ?? 'Tap to watch',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: AppColors.textOnAccent, size: 18),
                          SizedBox(width: 6),
                          Text('Watch Now',
                              style: TextStyle(
                                  color: AppColors.textOnAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick actions ───────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          _ActionTile(
            icon: Icons.newspaper_rounded,
            label: 'Guide',
            color: AppColors.accentBlue,
            onTap: () => context.push(RoutePaths.epg),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ActionTile(
            icon: Icons.history_rounded,
            label: 'History',
            color: AppColors.accentPurple,
            onTap: () => context.push(RoutePaths.history),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ActionTile(
            icon: Icons.favorite_rounded,
            label: 'Favorites',
            color: AppColors.accentGold,
            onTap: () => context.goNamed(RouteNames.favorites),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ActionTile(
            icon: Icons.tune_rounded,
            label: 'Settings',
            color: AppColors.textSecondary,
            onTap: () => context.goNamed(RouteNames.settings),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.base),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Horizontal channel section ──────────────────────────────

class _ChannelHorizontalSection extends StatelessWidget {
  const _ChannelHorizontalSection({
    required this.title,
    required this.channels,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final List<Channel> channels;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          actionLabel: actionLabel,
          onActionTap: onAction,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: channels.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.cardGapMedium),
            itemBuilder: (context, index) {
              final ch = channels[index];
              return SizedBox(
                width: 120,
                child: ChannelCard(
                  name: ch.name,
                  logoUrl: ch.logoUrl,
                  isLive: ch.isLive,
                  onTap: () => context.push('/player/${ch.id}'),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
      ],
    );
  }
}
