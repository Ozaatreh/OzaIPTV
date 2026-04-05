import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/environment.dart';
import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/spacing.dart';
import '../../../../domain/entities/playback_session.dart';
import '../../../../services/playback/playback_controller.dart';
import '../../../../services/playback/stream_fallback_manager.dart';

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ps = ref.watch(playbackControllerProvider);
    final fm = ref.watch(streamFallbackManagerProvider);
    final timeFormat = DateFormat('HH:mm:ss.SSS');

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(title: const Text('Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          _Section(title: 'PLAYER STATE', items: [
            _Item('Status', ps.playbackState.displayName,
                color: ps.isPlaying ? AppColors.success
                    : ps.hasError ? AppColors.error
                    : AppColors.textSecondary),
            _Item('Channel', ps.currentChannel?.name ?? 'None'),
            _Item('Channel ID', ps.currentChannel?.id ?? '—'),
          ]),

          _Section(title: 'CURRENT SOURCE', items: [
            _Item('Source', ps.currentSource?.name ?? 'None'),
            _Item('URL', ps.currentSource?.url ?? '—', mono: true),
            _Item('Protocol', ps.currentSource?.protocol.displayName ?? '—'),
            _Item('Priority', ps.currentSource?.priority.toString() ?? '—'),
            _Item('Health Score',
                ps.currentSource != null
                    ? '${ps.currentSource!.healthScore.toStringAsFixed(0)}%'
                    : '—',
                color: (ps.currentSource?.healthScore ?? 0) >= 80
                    ? AppColors.success : AppColors.warning),
          ]),

          _Section(title: 'FALLBACK', items: [
            _Item('Fallback Count', ps.fallbackCount.toString(),
                color: ps.fallbackCount > 0 ? AppColors.warning : AppColors.success),
            _Item('Retry Count', ps.retryCount.toString()),
            _Item('Available Sources',
                ps.currentChannel?.activeSources.length.toString() ?? '0'),
            _Item('Total Sources',
                ps.currentChannel?.streamSources.length.toString() ?? '0'),
          ]),

          if (ps.errorMessage != null)
            _Section(title: 'LAST ERROR', items: [
              _Item('Error', ps.errorMessage!, color: AppColors.error),
            ]),

          // Full event log with enriched data
          if (fm.events.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const Text('FALLBACK EVENT LOG',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    letterSpacing: 1.2, color: AppColors.accentGold)),
            const SizedBox(height: AppSpacing.sm),
            ...fm.events.reversed.take(20).map((e) =>
                _EventCard(event: e, timeFormat: timeFormat)),
          ],

          _Section(title: 'APP INFO', items: [
            _Item('Version', EnvironmentConfig.appVersion),
            _Item('Build', EnvironmentConfig.appBuildNumber.toString()),
            _Item('Environment', EnvironmentConfig.current.name),
            _Item('Mock Data', EnvironmentConfig.enableMockData ? 'Enabled' : 'Disabled'),
          ]),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.timeFormat});
  final FallbackEvent event;
  final DateFormat timeFormat;

  Color get _color => switch (event.type) {
        FallbackEventType.success => AppColors.success,
        FallbackEventType.retried => AppColors.warning,
        FallbackEventType.switched => AppColors.accentBlue,
        FallbackEventType.failed => AppColors.error,
        FallbackEventType.allExhausted => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(event.type.name.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: _color, letterSpacing: 0.5)),
            ),
            const Spacer(),
            Text(timeFormat.format(event.timestamp),
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ]),
          const SizedBox(height: 6),

          // Source name
          Text('Source: ${event.sourceName}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),

          // URL (truncated)
          Text(event.sourceUrl,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary,
                  fontFamily: 'monospace')),
          const SizedBox(height: 4),

          // Reason
          Text(event.reason,
              style: TextStyle(fontSize: 12, color: _color)),

          // Exception detail if present
          if (event.exception != null) ...[
            const SizedBox(height: 4),
            Text('Exception: ${event.exception}',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary,
                    fontFamily: 'monospace')),
          ],

          // Retry count
          if (event.retryAttempt > 0) ...[
            const SizedBox(height: 4),
            Text('Retry attempt: ${event.retryAttempt}',
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});
  final String title;
  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: AppSpacing.lg),
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          letterSpacing: 1.2, color: AppColors.accentGold)),
      const SizedBox(height: AppSpacing.sm),
      Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(color: AppColors.borderSubtle, width: 0.5)),
        child: Column(children: items.asMap().entries.map((e) =>
            e.value._build(isLast: e.key == items.length - 1)).toList()),
      ),
    ]);
  }
}

class _Item {
  const _Item(this.label, this.value, {this.color, this.mono = false});
  final String label;
  final String value;
  final Color? color;
  final bool mono;

  Widget _build({bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(border: isLast ? null : const Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5))),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
        const SizedBox(width: 12),
        Expanded(child: Text(value, textAlign: TextAlign.right, maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: mono ? 11 : 13, fontWeight: FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
                color: color ?? AppColors.textPrimary))),
      ]),
    );
  }
}
