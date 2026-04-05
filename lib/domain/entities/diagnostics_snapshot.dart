import 'package:equatable/equatable.dart';

import 'playback_session.dart';

/// A point-in-time diagnostic snapshot of the app and player state.
class DiagnosticsSnapshot extends Equatable {
  const DiagnosticsSnapshot({
    required this.timestamp,
    this.currentChannelId,
    this.currentSourceId,
    this.currentSourceUrl,
    this.sourcePriority,
    this.playerState = PlaybackState.idle,
    this.fallbackCount = 0,
    this.retryCount = 0,
    this.bufferHealth = 0,
    this.lastError,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
    this.buildNumber,
    this.platform,
    this.connectionType,
    this.availableSources = 0,
    this.totalSourcesForChannel = 0,
  });

  final DateTime timestamp;
  final String? currentChannelId;
  final String? currentSourceId;
  final String? currentSourceUrl;
  final int? sourcePriority;
  final PlaybackState playerState;
  final int fallbackCount;
  final int retryCount;
  final double bufferHealth;
  final String? lastError;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;
  final String? buildNumber;
  final String? platform;
  final String? connectionType;
  final int availableSources;
  final int totalSourcesForChannel;

  @override
  List<Object?> get props => [timestamp, currentChannelId, currentSourceId];
}
