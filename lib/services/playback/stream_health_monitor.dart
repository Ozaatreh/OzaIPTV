import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final streamHealthMonitorProvider = Provider<StreamHealthMonitor>(
  (ref) => StreamHealthMonitor(),
);

/// Persists stream health scores across app sessions.
/// Updated on every success/failure event from the fallback system.
class StreamHealthMonitor {
  Box<String> get _box => Hive.box<String>('stream_health');

  Future<void> recordSuccess(String sourceId) async {
    final data = _getData(sourceId);
    data['consecutiveFailures'] = 0;
    data['lastSuccess'] = DateTime.now().toIso8601String();
    data['totalSuccesses'] = (data['totalSuccesses'] as int? ?? 0) + 1;
    data['healthScore'] = _score(data);
    await _box.put(sourceId, json.encode(data));
  }

  Future<void> recordFailure(String sourceId, String reason) async {
    final data = _getData(sourceId);
    data['consecutiveFailures'] =
        (data['consecutiveFailures'] as int? ?? 0) + 1;
    data['totalFailures'] = (data['totalFailures'] as int? ?? 0) + 1;
    data['lastFailure'] = DateTime.now().toIso8601String();
    data['lastFailureReason'] = reason;
    data['healthScore'] = _score(data);
    await _box.put(sourceId, json.encode(data));
  }

  double getHealthScore(String sourceId) {
    final data = _getData(sourceId);
    return (data['healthScore'] as num?)?.toDouble() ?? 100.0;
  }

  String? getLastWorkingSource(String channelId) {
    return _box.get('lkg_$channelId');
  }

  Future<void> saveLastWorkingSource(
    String channelId,
    String sourceId,
  ) async {
    await _box.put('lkg_$channelId', sourceId);
  }

  Map<String, dynamic> _getData(String sourceId) {
    final raw = _box.get(sourceId);
    if (raw == null) {
      return {
        'sourceId': sourceId,
        'healthScore': 100.0,
        'consecutiveFailures': 0,
        'totalSuccesses': 0,
        'totalFailures': 0,
      };
    }
    return json.decode(raw) as Map<String, dynamic>;
  }

  double _score(Map<String, dynamic> data) {
    final s = (data['totalSuccesses'] as int? ?? 0);
    final f = (data['totalFailures'] as int? ?? 0);
    final c = (data['consecutiveFailures'] as int? ?? 0);
    final total = s + f;
    if (total == 0) return 100.0;
    var score = (s / total) * 100;
    score -= c * 15;
    return score.clamp(0.0, 100.0);
  }
}
