import 'package:equatable/equatable.dart';

/// Represents a single EPG (Electronic Program Guide) entry.
class EpgProgram extends Equatable {
  const EpgProgram({
    required this.id,
    required this.channelId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.category,
    this.posterUrl,
    this.isLive = false,
    this.rating,
    this.language,
  });

  final String id;
  final String channelId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final String? category;
  final String? posterUrl;
  final bool isLive;
  final String? rating;
  final String? language;

  Duration get duration => endTime.difference(startTime);

  double get progress {
    final now = DateTime.now();
    if (now.isBefore(startTime)) return 0;
    if (now.isAfter(endTime)) return 1;
    final elapsed = now.difference(startTime).inSeconds;
    final total = duration.inSeconds;
    return total > 0 ? elapsed / total : 0;
  }

  bool get isCurrentlyAiring {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isUpcoming => DateTime.now().isBefore(startTime);
  bool get hasPassed => DateTime.now().isAfter(endTime);

  @override
  List<Object?> get props => [id, channelId, startTime];
}
