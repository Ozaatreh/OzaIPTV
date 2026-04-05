import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/environment.dart';
import '../../../../data/repositories/settings_repository_impl.dart';
import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/spacing.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../routing/route_names.dart';

final appSettingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._ref) : super(const AppSettings()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    state = await _ref.read(settingsRepositoryProvider).getSettings();
  }

  Future<void> update(AppSettings Function(AppSettings) fn) async {
    state = fn(state);
    await _ref.read(settingsRepositoryProvider).saveSettings(state);
  }

  Future<void> reset() async {
    await _ref.read(settingsRepositoryProvider).resetSettings();
    state = const AppSettings();
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        children: [
          // ── Playback ──────────────────────────────────
          _sectionTitle('Playback'),
          _SettingsTile(
            icon: Icons.play_circle_outline_rounded,
            title: 'Autoplay',
            subtitle: 'Start playing when channel is selected',
            trailing: Switch(
              value: settings.autoplayEnabled,
              activeColor: AppColors.accentGold,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .update((s) => s.copyWith(autoplayEnabled: v)),
            ),
          ),
          _SettingsTile(
            icon: Icons.hd_outlined,
            title: 'Stream Quality',
            subtitle: settings.streamQuality.name[0].toUpperCase() +
                settings.streamQuality.name.substring(1),
            onTap: () => _showQualityPicker(context, ref, settings),
          ),
          _SettingsTile(
            icon: Icons.speed_rounded,
            title: 'Hardware Acceleration',
            subtitle: 'Use GPU for video decoding',
            trailing: Switch(
              value: settings.hardwareAcceleration,
              activeColor: AppColors.accentGold,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .update((s) => s.copyWith(hardwareAcceleration: v)),
            ),
          ),

          // ── Appearance ────────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Appearance'),
          _SettingsTile(
            icon: Icons.home_outlined,
            title: 'Startup Page',
            subtitle: _startupPageLabel(settings.startupPage),
            onTap: () => _showStartupPicker(context, ref, settings),
          ),
          _SettingsTile(
            icon: Icons.tv_outlined,
            title: 'Show EPG Overlay',
            subtitle: 'Display current program info in player',
            trailing: Switch(
              value: settings.showEpgOverlay,
              activeColor: AppColors.accentGold,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .update((s) => s.copyWith(showEpgOverlay: v)),
            ),
          ),

          // ── Data ──────────────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Data'),
          _SettingsTile(
            icon: Icons.cached_rounded,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.language_rounded,
            title: 'Preferred Language',
            subtitle: _languageLabel(settings.preferredLanguage),
            onTap: () {},
          ),

          // ── Advanced ──────────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Advanced'),
          _SettingsTile(
            icon: Icons.bug_report_outlined,
            title: 'Diagnostics',
            subtitle: 'Stream health, debug info',
            onTap: () => context.goNamed(RouteNames.diagnostics),
          ),
          _SettingsTile(
            icon: Icons.restore_rounded,
            title: 'Reset All Settings',
            subtitle: 'Restore default configuration',
            onTap: () => _confirmReset(context, ref),
          ),

          // ── About ─────────────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'App Version',
            subtitle:
                '${EnvironmentConfig.appVersion} (${EnvironmentConfig.appBuildNumber})',
          ),
          _SettingsTile(
            icon: Icons.code_rounded,
            title: 'Environment',
            subtitle: EnvironmentConfig.current.name,
          ),

          const SizedBox(height: AppSpacing.huge),
          Center(
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.live_tv_rounded,
                      color: AppColors.textOnAccent, size: 24),
                ),
                const SizedBox(height: 10),
                const Text('OzaIPTV',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Premium Streaming Experience',
                    style: TextStyle(
                        color: AppColors.accentGold.withValues(alpha: 0.6),
                        fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.accentGold),
      ),
    );
  }

  String _startupPageLabel(StartupPage page) => switch (page) {
        StartupPage.home => 'Home',
        StartupPage.liveTv => 'Live TV',
        StartupPage.favorites => 'Favorites',
        StartupPage.lastWatched => 'Last Watched',
      };

  String _languageLabel(String code) => switch (code) {
        'en' => 'English',
        'ar' => 'Arabic',
        'fr' => 'French',
        'es' => 'Spanish',
        _ => code,
      };

  void _showQualityPicker(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: StreamQuality.values.map((q) {
          final isSelected = q == settings.streamQuality;
          return ListTile(
            title: Text(q.name[0].toUpperCase() + q.name.substring(1)),
            trailing: isSelected
                ? const Icon(Icons.check_rounded,
                    color: AppColors.accentGold)
                : null,
            onTap: () {
              ref
                  .read(appSettingsProvider.notifier)
                  .update((s) => s.copyWith(streamQuality: q));
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showStartupPicker(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: StartupPage.values.map((p) {
          final isSelected = p == settings.startupPage;
          return ListTile(
            title: Text(_startupPageLabel(p)),
            trailing: isSelected
                ? const Icon(Icons.check_rounded,
                    color: AppColors.accentGold)
                : null,
            onTap: () {
              ref
                  .read(appSettingsProvider.notifier)
                  .update((s) => s.copyWith(startupPage: p));
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
            'This will restore all settings to their defaults.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(appSettingsProvider.notifier).reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfacePrimary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child:
                    Icon(icon, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textTertiary)),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
