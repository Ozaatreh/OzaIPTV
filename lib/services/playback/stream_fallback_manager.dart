import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../app/environment.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/stream_source.dart';

final streamFallbackManagerProvider =
    Provider<StreamFallbackManager>((ref) => StreamFallbackManager());

/// Manages automatic failover between stream sources.
///
/// Fixed issues from v1:
/// - No longer calls onSourceSuccess prematurely
/// - Tracks per-source retry with configurable max
/// - Records full URL + exception in every event
/// - Guards against duplicate failure reports
class StreamFallbackManager {
  final _logger = Logger(printer: SimplePrinter());
  final List<FallbackEvent> _events = [];

  Channel? _currentChannel;
  List<StreamSource> _orderedSources = [];
  int _currentSourceIndex = 0;
  int _retryCountForCurrentSource = 0;
  String? _lastKnownWorkingSourceId;
  bool _isProcessingFailure = false;

  void initializeForChannel(Channel channel, {String? lastWorkingSourceId}) {
    _currentChannel = channel;
    _lastKnownWorkingSourceId = lastWorkingSourceId;
    _currentSourceIndex = 0;
    _retryCountForCurrentSource = 0;
    _isProcessingFailure = false;
    _events.clear();
    _orderedSources = _buildSourceOrder(channel.activeSources);
    _logger.i(
      'Fallback init: ${channel.name} — '
      '${_orderedSources.length} sources available',
    );
  }

  StreamSource? get currentSource {
    if (_currentSourceIndex >= _orderedSources.length) return null;
    return _orderedSources[_currentSourceIndex];
  }

  bool get hasMoreSources => _currentSourceIndex < _orderedSources.length - 1;
  bool get allSourcesExhausted => _currentSourceIndex >= _orderedSources.length;
  int get fallbackCount =>
      _events.where((e) => e.type == FallbackEventType.switched).length;
  int get totalRetryCount =>
      _events.where((e) => e.type == FallbackEventType.retried).length;
  List<FallbackEvent> get events => List.unmodifiable(_events);
  String? get lastKnownWorkingSourceId => _lastKnownWorkingSourceId;

  /// Called when the current source fails.
  /// Returns the next source to try, or null if all exhausted.
  ///
  /// CRITICAL FIX: Guards against re-entrant calls from duplicate
  /// error callbacks (video_player fires listener multiple times).
  StreamSource? onSourceFailed({
    required String reason,
    String? exception,
  }) {
    if (_isProcessingFailure) return null;
    _isProcessingFailure = true;

    try {
      return _doSourceFailed(reason: reason, exception: exception);
    } finally {
      // Release after a microtask to let state settle
      Future.microtask(() => _isProcessingFailure = false);
    }
  }

  StreamSource? _doSourceFailed({
    required String reason,
    String? exception,
  }) {
    final failed = currentSource;
    if (failed == null) return null;

    // Retry once before switching
    if (_retryCountForCurrentSource < 1) {
      _retryCountForCurrentSource++;
      _events.add(FallbackEvent(
        type: FallbackEventType.retried,
        sourceId: failed.id,
        sourceName: failed.name,
        sourceUrl: failed.url,
        reason: reason,
        exception: exception,
        retryAttempt: _retryCountForCurrentSource,
        timestamp: DateTime.now(),
      ));
      _logger.w(
        'RETRY ${failed.name} (attempt $_retryCountForCurrentSource) — $reason',
      );
      return failed;
    }

    // Source exhausted after retry — record failure
    _events.add(FallbackEvent(
      type: FallbackEventType.failed,
      sourceId: failed.id,
      sourceName: failed.name,
      sourceUrl: failed.url,
      reason: reason,
      exception: exception,
      retryAttempt: _retryCountForCurrentSource,
      timestamp: DateTime.now(),
    ));

    _currentSourceIndex++;
    _retryCountForCurrentSource = 0;

    if (allSourcesExhausted) {
      _events.add(FallbackEvent(
        type: FallbackEventType.allExhausted,
        sourceId: failed.id,
        sourceName: failed.name,
        sourceUrl: failed.url,
        reason: 'All ${_orderedSources.length} sources exhausted',
        exception: exception,
        retryAttempt: 0,
        timestamp: DateTime.now(),
      ));
      _logger.e('ALL EXHAUSTED for ${_currentChannel?.name}');
      return null;
    }

    final next = currentSource!;
    _events.add(FallbackEvent(
      type: FallbackEventType.switched,
      sourceId: next.id,
      sourceName: next.name,
      sourceUrl: next.url,
      reason: 'Switched from ${failed.name}: $reason',
      exception: null,
      retryAttempt: 0,
      timestamp: DateTime.now(),
    ));
    _logger.i(
      'SWITCH → ${next.name} '
      '(${_currentSourceIndex + 1}/${_orderedSources.length})',
    );
    return next;
  }

  void onSourceSuccess() {
    final source = currentSource;
    if (source == null) return;
    _lastKnownWorkingSourceId = source.id;
    _retryCountForCurrentSource = 0;
    _events.add(FallbackEvent(
      type: FallbackEventType.success,
      sourceId: source.id,
      sourceName: source.name,
      sourceUrl: source.url,
      reason: 'Playback started successfully',
      retryAttempt: 0,
      timestamp: DateTime.now(),
    ));
    _logger.i('SUCCESS: ${source.name}');
  }

  List<StreamSource> _buildSourceOrder(List<StreamSource> sources) {
    if (sources.isEmpty) return [];
    final sorted = List<StreamSource>.from(sources);
    sorted.sort((a, b) {
      final p = a.priority.compareTo(b.priority);
      if (p != 0) return p;
      return b.healthScore.compareTo(a.healthScore);
    });
    if (_lastKnownWorkingSourceId != null) {
      final idx = sorted.indexWhere((s) => s.id == _lastKnownWorkingSourceId);
      if (idx > 0) {
        final w = sorted.removeAt(idx);
        sorted.insert(0, w);
      }
    }
    return sorted.take(EnvironmentConfig.maxFallbackAttempts).toList();
  }

  void reset() {
    _currentChannel = null;
    _orderedSources.clear();
    _currentSourceIndex = 0;
    _retryCountForCurrentSource = 0;
    _isProcessingFailure = false;
    _events.clear();
  }
}

/// Enriched fallback event with full URL and exception details.
class FallbackEvent {
  const FallbackEvent({
    required this.type,
    required this.sourceId,
    required this.sourceName,
    required this.sourceUrl,
    required this.reason,
    required this.retryAttempt,
    required this.timestamp,
    this.exception,
  });

  final FallbackEventType type;
  final String sourceId;
  final String sourceName;
  final String sourceUrl;
  final String reason;
  final String? exception;
  final int retryAttempt;
  final DateTime timestamp;
}

enum FallbackEventType {
  retried,
  failed,
  switched,
  success,
  allExhausted,
}
