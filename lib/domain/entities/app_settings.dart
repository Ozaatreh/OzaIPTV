import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = AppThemeMode.dark,
    this.autoplayEnabled = true,
    this.preferredLanguage = 'en',
    this.startupPage = StartupPage.home,
    this.streamQuality = StreamQuality.auto,
    this.showEpgOverlay = true,
    this.enableNotifications = true,
    this.bufferDurationSeconds = 10,
    this.hardwareAcceleration = true,
  });

  final AppThemeMode themeMode;
  final bool autoplayEnabled;
  final String preferredLanguage;
  final StartupPage startupPage;
  final StreamQuality streamQuality;
  final bool showEpgOverlay;
  final bool enableNotifications;
  final int bufferDurationSeconds;
  final bool hardwareAcceleration;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? autoplayEnabled,
    String? preferredLanguage,
    StartupPage? startupPage,
    StreamQuality? streamQuality,
    bool? showEpgOverlay,
    bool? enableNotifications,
    int? bufferDurationSeconds,
    bool? hardwareAcceleration,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      autoplayEnabled: autoplayEnabled ?? this.autoplayEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      startupPage: startupPage ?? this.startupPage,
      streamQuality: streamQuality ?? this.streamQuality,
      showEpgOverlay: showEpgOverlay ?? this.showEpgOverlay,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      bufferDurationSeconds:
          bufferDurationSeconds ?? this.bufferDurationSeconds,
      hardwareAcceleration:
          hardwareAcceleration ?? this.hardwareAcceleration,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        autoplayEnabled,
        preferredLanguage,
        startupPage,
        streamQuality,
      ];
}

enum AppThemeMode { dark, light, system }

enum StartupPage { home, liveTv, favorites, lastWatched }

enum StreamQuality { auto, low, medium, high, ultra }
