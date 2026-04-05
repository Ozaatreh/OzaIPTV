import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers.dart';
import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/spacing.dart';
import '../../../../domain/entities/epg_program.dart';

/// Compact now/next EPG overlay shown inside the player.
class EpgNowNextOverlay extends ConsumerWidget {
  const EpgNowNextOverlay({required this.channelId, super.key});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(channelProgramsProvider(channelId));

    return programsAsync.when(
      data: (programs) {
        if (programs.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now();
        EpgProgram? currentProgram;
        EpgProgram? nextProgram;

        for (final p in programs) {
          if (p.startTime.isBefore(now) && p.endTime.isAfter(now)) {
            currentProgram = p;
          } else if (p.startTime.isAfter(now) && nextProgram == null) {
            nextProgram = p;
          }
        }

        if (currentProgram == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(AppSpacing.base),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(AppRadius.base),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Now playing
              _ProgramRow(
                label: 'NOW',
                labelColor: AppColors.accentGold,
                program: currentProgram,
                showProgress: true,
              ),

              if (nextProgram != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  child: Container(
                    height: 0.5,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                _ProgramRow(
                  label: 'NEXT',
                  labelColor: AppColors.textTertiary,
                  program: nextProgram,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ProgramRow extends StatelessWidget {
  const _ProgramRow({
    required this.label,
    required this.labelColor,
    required this.program,
    this.showProgress = false,
  });

  final String label;
  final Color labelColor;
  final EpgProgram program;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: labelColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${timeFormat.format(program.startTime)} – ${timeFormat.format(program.endTime)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          program.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        if (showProgress) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: program.progress,
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentGold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
