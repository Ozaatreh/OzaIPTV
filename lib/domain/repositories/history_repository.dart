import '../entities/watch_history_item.dart';

abstract class HistoryRepository {
  Future<List<WatchHistoryItem>> getHistory({int limit = 50});
  Future<void> addToHistory(WatchHistoryItem item);
  Future<void> removeFromHistory(String channelId);
  Future<void> clearHistory();
}
