import 'package:equatable/equatable.dart';

class WatchHistoryItem extends Equatable {
  const WatchHistoryItem({
    required this.channelId,
    required this.watchedAt,
    this.durationSeconds = 0,
    this.sourceId,
  });

  final String channelId;
  final DateTime watchedAt;
  final int durationSeconds;
  final String? sourceId;

  @override
  List<Object?> get props => [channelId, watchedAt];
}
