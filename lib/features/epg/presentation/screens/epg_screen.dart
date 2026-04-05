import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers.dart';
import '../../../../design_system/components/loading_states.dart';
import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/spacing.dart';
import '../../../../domain/entities/channel.dart';
import '../../../../domain/entities/epg_program.dart';

class EpgScreen extends ConsumerWidget {
  const EpgScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Program Guide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Jump to Now',
            onPressed: () {},
          ),
        ],
      ),
      body: channelsAsync.when(
        data: (channels) => _EpgGuideBody(channels: channels),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(channelsProvider),
        ),
      ),
    );
  }
}

class _EpgGuideBody extends ConsumerWidget {
  const _EpgGuideBody({required this.channels});

  final List<Channel> channels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (channels.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.tv_off_rounded,
        title: 'No channels available',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: channels.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final channel = channels[index];
        return _ChannelEpgRow(channel: channel);
      },
    );
  }
}

class _ChannelEpgRow extends ConsumerWidget {
  const _ChannelEpgRow({required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(channelProgramsProvider(channel.id));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/player/${channel.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel info column
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.liveRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.liveRed,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Programs timeline
              Expanded(
                child: programsAsync.when(
                  data: (programs) => _ProgramTimeline(programs: programs),
                  loading: () => const _ProgramTimelineSkeleton(),
                  error: (_, __) => const Text(
                    'EPG unavailable',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
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

class _ProgramTimeline extends StatelessWidget {
  const _ProgramTimeline({required this.programs});

  final List<EpgProgram> programs;

  @override
  Widget build(BuildContext context) {
    if (programs.isEmpty) {
      return const Text(
        'No program data',
        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
      );
    }

    final timeFormat = DateFormat('HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: programs.take(3).map((program) {
        final isCurrent = program.isCurrentlyAiring;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time
              SizedBox(
                width: 48,
                child: Text(
                  timeFormat.format(program.startTime),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isCurrent
                        ? AppColors.accentGold
                        : AppColors.textTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Indicator dot
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? AppColors.accentGold
                        : AppColors.textTertiary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Program info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.w400,
                        color: isCurrent
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 4),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: program.progress,
                          minHeight: 3,
                          backgroundColor: AppColors.surfacePrimary,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentGold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ProgramTimelineSkeleton extends StatelessWidget {
  const _ProgramTimelineSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
