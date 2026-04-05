import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers.dart';
import '../../../../data/repositories/history_repository_impl.dart';
import '../../../../design_system/components/loading_states.dart';
import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/spacing.dart';
import '../../../../domain/entities/channel.dart';
import '../../../../domain/entities/watch_history_item.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final channelsAsync = ref.watch(channelsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Watch History'),
        actions: [
          historyAsync.maybeWhen(
            data: (items) => items.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Clear History',
                    onPressed: () => _confirmClear(context, ref),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (historyItems) {
          if (historyItems.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history_rounded,
              title: 'No watch history',
              subtitle: 'Channels you watch will appear here',
            );
          }

          return channelsAsync.when(
            data: (channels) => _HistoryList(
              historyItems: historyItems,
              channels: channels,
              onRemove: (channelId) async {
                await ref
                    .read(historyRepositoryProvider)
                    .removeFromHistory(channelId);
                ref.invalidate(historyProvider);
              },
            ),
            loading: () => const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentGold),
            ),
            error: (e, _) => ErrorStateWidget(message: e.toString()),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(historyProvider),
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Remove all watch history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(historyRepositoryProvider).clearHistory();
              ref.invalidate(historyProvider);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.historyItems,
    required this.channels,
    required this.onRemove,
  });

  final List<WatchHistoryItem> historyItems;
  final List<Channel> channels;
  final ValueChanged<String> onRemove;

  Channel? _findChannel(String channelId) {
    try {
      return channels.firstWhere((c) => c.id == channelId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group by date
    final grouped = <String, List<_HistoryEntry>>{};
    final dateFormat = DateFormat('MMMM d, yyyy');
    final today = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final yesterday = DateFormat('MMMM d, yyyy')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    for (final item in historyItems) {
      final channel = _findChannel(item.channelId);
      if (channel == null) continue;

      var dateLabel = dateFormat.format(item.watchedAt);
      if (dateLabel == today) {
        dateLabel = 'Today';
      } else if (dateLabel == yesterday) {
        dateLabel = 'Yesterday';
      }

      grouped.putIfAbsent(dateLabel, () => []);
      grouped[dateLabel]!.add(_HistoryEntry(item: item, channel: channel));
    }

    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.lg,
                AppSpacing.base,
                AppSpacing.sm,
              ),
              child: Text(
                section.key,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            // Items
            ...section.value.map(
              (entry) => _HistoryTile(
                entry: entry,
                onTap: () =>
                    context.push('/player/${entry.channel.id}'),
                onDismiss: () => onRemove(entry.channel.id),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryEntry {
  const _HistoryEntry({required this.item, required this.channel});
  final WatchHistoryItem item;
  final Channel channel;
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onDismiss,
  });

  final _HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Dismissible(
      key: Key(
        '${entry.item.channelId}_${entry.item.watchedAt.millisecondsSinceEpoch}',
      ),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: AppColors.error.withValues(alpha: 0.2),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                // Channel icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfacePrimary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.live_tv_rounded,
                        color: AppColors.textTertiary,
                        size: 24,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfacePrimary,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.accentGold,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Watched at ${timeFormat.format(entry.item.watchedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry.item.durationSeconds > 0)
                  Text(
                    _formatDuration(entry.item.durationSeconds),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
    return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
  }
}
