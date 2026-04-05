import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

class SettingsRepositoryImpl implements SettingsRepository {
  static const _key = 'app_settings';

  Box<String> get _box => Hive.box<String>('settings');

  @override
  Future<AppSettings> getSettings() async {
    final raw = _box.get(_key);
    if (raw == null) return const AppSettings();

    final map = json.decode(raw) as Map<String, dynamic>;
    return AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == map['themeMode'],
        orElse: () => AppThemeMode.dark,
      ),
      autoplayEnabled: map['autoplayEnabled'] as bool? ?? true,
      preferredLanguage: map['preferredLanguage'] as String? ?? 'en',
      startupPage: StartupPage.values.firstWhere(
        (e) => e.name == map['startupPage'],
        orElse: () => StartupPage.home,
      ),
      streamQuality: StreamQuality.values.firstWhere(
        (e) => e.name == map['streamQuality'],
        orElse: () => StreamQuality.auto,
      ),
      showEpgOverlay: map['showEpgOverlay'] as bool? ?? true,
      enableNotifications: map['enableNotifications'] as bool? ?? true,
      bufferDurationSeconds: map['bufferDurationSeconds'] as int? ?? 10,
      hardwareAcceleration: map['hardwareAcceleration'] as bool? ?? true,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final map = {
      'themeMode': settings.themeMode.name,
      'autoplayEnabled': settings.autoplayEnabled,
      'preferredLanguage': settings.preferredLanguage,
      'startupPage': settings.startupPage.name,
      'streamQuality': settings.streamQuality.name,
      'showEpgOverlay': settings.showEpgOverlay,
      'enableNotifications': settings.enableNotifications,
      'bufferDurationSeconds': settings.bufferDurationSeconds,
      'hardwareAcceleration': settings.hardwareAcceleration,
    };
    await _box.put(_key, json.encode(map));
  }

  @override
  Future<void> resetSettings() async {
    await _box.delete(_key);
  }
}
