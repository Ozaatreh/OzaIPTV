import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../app/environment.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/playback_session.dart';
import '../../domain/entities/stream_source.dart';
import 'stream_fallback_manager.dart';
import 'stream_health_monitor.dart';
import 'stream_validator.dart';

final playbackControllerProvider =
    StateNotifierProvider<PlaybackController, PlaybackSessionState>((ref) {
  return PlaybackController(
    ref.watch(streamFallbackManagerProvider),
    ref.watch(streamHealthMonitorProvider),
    ref.watch(streamValidatorProvider),
  );
});

/// Orchestrates the full playback lifecycle with proper error handling.
///
/// FIXES from v1 audit:
/// 1. Does NOT call onSourceSuccess prematurely — waits for
///    confirmPlaybackStarted() from the UI layer.
/// 2. Debounces error reports — ignores duplicates within 2 seconds.
/// 3. Validates URLs before attempting playback.
/// 4. Enforces startup timeout via the UI layer.
/// 5. Integrates with StreamHealthMonitor for persistent scores.
/// 6. Persists last-known-good source per channel.
class PlaybackController extends StateNotifier<PlaybackSessionState> {
  PlaybackController(
    this._fallbackManager,
    this._healthMonitor,
    this._validator,
  ) : super(const PlaybackSessionState());

  final StreamFallbackManager _fallbackManager;
  final StreamHealthMonitor _healthMonitor;
  final StreamValidator _validator;
  final _logger = Logger(printer: SimplePrinter());
  Timer? _healthCheckTimer;
  DateTime? _lastErrorTime;
  String? _lastErrorMsg;

  // ── Channel lifecycle ─────────────────────────────────────

  Future<void> playChannel(Channel channel) async {
    if (channel.activeSources.isEmpty) {
      state = state.copyWith(
        playbackState: PlaybackState.error,
        errorMessage: 'No stream sources available for ${channel.name}',
        currentChannel: channel,
      );
      return;
    }

    _stopHealthMonitoring();
    _lastErrorTime = null;
    _lastErrorMsg = null;

    // Retrieve last-known-good source for this channel
    final lkg = _healthMonitor.getLastWorkingSource(channel.id);

    state = PlaybackSessionState(
      currentChannel: channel,
      playbackState: PlaybackState.loading,
    );

    _fallbackManager.initializeForChannel(channel, lastWorkingSourceId: lkg);
    final source = _fallbackManager.currentSource;

    if (source == null) {
      state = state.copyWith(
        playbackState: PlaybackState.error,
        errorMessage: 'No healthy sources available',
      );
      return;
    }

    await _attemptSource(source);
  }

  /// Attempt a source: validate, then signal UI to connect.
  Future<void> _attemptSource(StreamSource source) async {
    state = state.copyWith(
      currentSource: source,
      playbackState: PlaybackState.loading,
      errorMessage: null,
    );

    _logger.i('ATTEMPT: ${source.name} → ${source.url}');

    // Step 1: Quick URL validation
    final validation = await _validator.validate(source);

    if (!validation.isValid) {
      _logger.w('VALIDATION FAILED: ${source.name} — ${validation.reason}');
      _onSourceFailed(
        reason: 'Validation failed: ${validation.reason}',
        exception: validation.reason,
      );
      return;
    }

    _logger.d('VALIDATED: ${source.name} (${validation.latencyMs}ms)');

    // Step 2: Signal UI to initialize the video player.
    // The UI layer calls confirmPlaybackStarted() on success,
    // or reportPlaybackError() on failure.
    // We stay in "loading" state until one of those happens.
    state = state.copyWith(
      playbackState: PlaybackState.loading,
      fallbackCount: _fallbackManager.fallbackCount,
      retryCount: _fallbackManager.totalRetryCount,
    );
  }

  // ── Called by UI layer ─────────────────────────────────────

  /// UI confirms the video player started playing successfully.
  /// THIS is when we record success — not before.
  void confirmPlaybackStarted() {
    final source = state.currentSource;
    if (source == null) return;

    _fallbackManager.onSourceSuccess();
    _healthMonitor.recordSuccess(source.id);

    // Persist last-known-good
    final channelId = state.currentChannel?.id;
    if (channelId != null) {
      _healthMonitor.saveLastWorkingSource(channelId, source.id);
    }

    state = state.copyWith(
      playbackState: PlaybackState.playing,
      errorMessage: null,
      fallbackCount: _fallbackManager.fallbackCount,
      retryCount: _fallbackManager.totalRetryCount,
    );

    _startHealthMonitoring();
    _logger.i('PLAYING: ${source.name}');
  }

  /// UI reports a playback error (initialization fail or mid-stream).
  ///
  /// CRITICAL FIX: Debounces duplicate errors. video_player's listener
  /// fires multiple times for the same error, causing cascading fallbacks.
  void reportPlaybackError(String error) {
    final now = DateTime.now();

    // Debounce: ignore same error within 2 seconds
    if (_lastErrorMsg == error &&
        _lastErrorTime != null &&
        now.difference(_lastErrorTime!).inMilliseconds < 2000) {
      _logger.d('DEBOUNCED duplicate error: $error');
      return;
    }

    // Also ignore errors when we're already in error/switching state
    if (state.playbackState == PlaybackState.error ||
        state.playbackState == PlaybackState.switching) {
      _logger.d('IGNORED error (already handling): $error');
      return;
    }

    _lastErrorTime = now;
    _lastErrorMsg = error;

    _logger.w('PLAYER ERROR: $error');
    _onSourceFailed(reason: 'Player error', exception: error);
  }

  // ── Internal fallback flow ─────────────────────────────────

  void _onSourceFailed({required String reason, String? exception}) {
    final failedSource = state.currentSource;
    if (failedSource != null) {
      _healthMonitor.recordFailure(failedSource.id, reason);
    }

    final nextSource = _fallbackManager.onSourceFailed(
      reason: reason,
      exception: exception,
    );

    if (nextSource == null) {
      state = state.copyWith(
        playbackState: PlaybackState.error,
        errorMessage: 'All stream sources failed. Please try again later.',
        fallbackCount: _fallbackManager.fallbackCount,
        retryCount: _fallbackManager.totalRetryCount,
      );
      _stopHealthMonitoring();
      return;
    }

    state = state.copyWith(
      playbackState: PlaybackState.switching,
      fallbackCount: _fallbackManager.fallbackCount,
      retryCount: _fallbackManager.totalRetryCount,
    );

    // Small delay before retry/switch to let player cleanup
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _attemptSource(nextSource);
    });
  }

  // ── User actions ───────────────────────────────────────────

  void retry() {
    final channel = state.currentChannel;
    if (channel != null) playChannel(channel);
  }

  Future<void> playNextChannel(List<Channel> channelList) async {
    final current = state.currentChannel;
    if (current == null || channelList.isEmpty) return;
    final idx = channelList.indexWhere((c) => c.id == current.id);
    final nextIdx = (idx + 1) % channelList.length;
    await playChannel(channelList[nextIdx]);
  }

  Future<void> playPreviousChannel(List<Channel> channelList) async {
    final current = state.currentChannel;
    if (current == null || channelList.isEmpty) return;
    final idx = channelList.indexWhere((c) => c.id == current.id);
    final prevIdx = idx <= 0 ? channelList.length - 1 : idx - 1;
    await playChannel(channelList[prevIdx]);
  }

  void pause() {
    if (state.playbackState == PlaybackState.playing) {
      state = state.copyWith(playbackState: PlaybackState.paused);
    }
  }

  void resume() {
    if (state.playbackState == PlaybackState.paused ||
        state.playbackState == PlaybackState.loading) {
      state = state.copyWith(playbackState: PlaybackState.playing);
    }
  }

  void stop() {
    _stopHealthMonitoring();
    _fallbackManager.reset();
    _lastErrorTime = null;
    _lastErrorMsg = null;
    state = const PlaybackSessionState();
  }

  // ── Health monitoring ──────────────────────────────────────

  void _startHealthMonitoring() {
    _stopHealthMonitoring();
    _healthCheckTimer = Timer.periodic(
      Duration(seconds: EnvironmentConfig.healthCheckIntervalSeconds),
      (_) {},
    );
  }

  void _stopHealthMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  @override
  void dispose() {
    _stopHealthMonitoring();
    super.dispose();
  }
}

/// Immutable state exposed by PlaybackController.
class PlaybackSessionState {
  const PlaybackSessionState({
    this.currentChannel,
    this.currentSource,
    this.playbackState = PlaybackState.idle,
    this.errorMessage,
    this.fallbackCount = 0,
    this.retryCount = 0,
  });

  final Channel? currentChannel;
  final StreamSource? currentSource;
  final PlaybackState playbackState;
  final String? errorMessage;
  final int fallbackCount;
  final int retryCount;

  bool get isPlaying => playbackState == PlaybackState.playing;
  bool get isLoading => playbackState == PlaybackState.loading;
  bool get hasError => playbackState == PlaybackState.error;
  bool get isSwitching => playbackState == PlaybackState.switching;

  PlaybackSessionState copyWith({
    Channel? currentChannel,
    StreamSource? currentSource,
    PlaybackState? playbackState,
    String? errorMessage,
    int? fallbackCount,
    int? retryCount,
  }) {
    return PlaybackSessionState(
      currentChannel: currentChannel ?? this.currentChannel,
      currentSource: currentSource ?? this.currentSource,
      playbackState: playbackState ?? this.playbackState,
      errorMessage: errorMessage ?? this.errorMessage,
      fallbackCount: fallbackCount ?? this.fallbackCount,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
