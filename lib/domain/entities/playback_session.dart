import 'package:equatable/equatable.dart';

/// Tracks the state of a single playback session, including
/// source switches, retries, and fallback events.
class PlaybackSession extends Equatable {
  const PlaybackSession({
    required this.id,
    required this.channelId,
    required this.sourceId,
    required this.startedAt,
    this.endedAt,
    this.state = PlaybackState.idle,
    this.fallbackCount = 0,
    this.retryCount = 0,
    this.bufferEvents = 0,
    this.lastError,
    this.sourceHistory = const [],
  });

  final String id;
  final String channelId;
  final String sourceId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final PlaybackState state;
  final int fallbackCount;
  final int retryCount;
  final int bufferEvents;
  final String? lastError;
  final List<String> sourceHistory;

  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  PlaybackSession copyWith({
    String? id,
    String? channelId,
    String? sourceId,
    DateTime? startedAt,
    DateTime? endedAt,
    PlaybackState? state,
    int? fallbackCount,
    int? retryCount,
    int? bufferEvents,
    String? lastError,
    List<String>? sourceHistory,
  }) {
    return PlaybackSession(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      sourceId: sourceId ?? this.sourceId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      state: state ?? this.state,
      fallbackCount: fallbackCount ?? this.fallbackCount,
      retryCount: retryCount ?? this.retryCount,
      bufferEvents: bufferEvents ?? this.bufferEvents,
      lastError: lastError ?? this.lastError,
      sourceHistory: sourceHistory ?? this.sourceHistory,
    );
  }

  @override
  List<Object?> get props => [id, channelId, sourceId];
}

enum PlaybackState {
  idle,
  loading,
  buffering,
  playing,
  paused,
  error,
  switching,
  ended;

  bool get isActive =>
      this == PlaybackState.loading ||
      this == PlaybackState.buffering ||
      this == PlaybackState.playing ||
      this == PlaybackState.switching;

  String get displayName => switch (this) {
        PlaybackState.idle => 'Idle',
        PlaybackState.loading => 'Loading',
        PlaybackState.buffering => 'Buffering',
        PlaybackState.playing => 'Playing',
        PlaybackState.paused => 'Paused',
        PlaybackState.error => 'Error',
        PlaybackState.switching => 'Switching Source',
        PlaybackState.ended => 'Ended',
      };
}
