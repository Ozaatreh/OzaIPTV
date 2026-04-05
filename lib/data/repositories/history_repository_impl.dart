import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../app/environment.dart';
import '../../domain/entities/watch_history_item.dart';
import '../../domain/repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl();
});

class HistoryRepositoryImpl implements HistoryRepository {
  Box<String> get _box => Hive.box<String>('history');

  @override
  Future<List<WatchHistoryItem>> getHistory({int limit = 50}) async {
    final items = <WatchHistoryItem>[];
    for (final key in _box.keys) {
      final raw = _box.get(key as String);
      if (raw != null) {
        final map = json.decode(raw) as Map<String, dynamic>;
        items.add(WatchHistoryItem(
          channelId: map['channelId'] as String,
          watchedAt: DateTime.parse(map['watchedAt'] as String),
          durationSeconds: map['durationSeconds'] as int? ?? 0,
          sourceId: map['sourceId'] as String?,
        ));
      }
    }
    items.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return items.take(limit).toList();
  }

  @override
  Future<void> addToHistory(WatchHistoryItem item) async {
    // Enforce max history size
    if (_box.length >= EnvironmentConfig.maxHistoryItems) {
      final oldest = _box.keys.first;
      await _box.delete(oldest);
    }

    final key = '${item.channelId}_${item.watchedAt.millisecondsSinceEpoch}';
    final map = {
      'channelId': item.channelId,
      'watchedAt': item.watchedAt.toIso8601String(),
      'durationSeconds': item.durationSeconds,
      'sourceId': item.sourceId,
    };
    await _box.put(key, json.encode(map));
  }

  @override
  Future<void> removeFromHistory(String channelId) async {
    final keysToRemove = _box.keys
        .where((k) => (k as String).startsWith(channelId))
        .toList();
    for (final key in keysToRemove) {
      await _box.delete(key);
    }
  }

  @override
  Future<void> clearHistory() async {
    await _box.clear();
  }
}
