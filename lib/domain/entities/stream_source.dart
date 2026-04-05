import 'package:equatable/equatable.dart';

import '../../core/enums/stream_protocol.dart';

/// Represents a single stream source for a channel.
///
/// Each channel can have multiple sources with different
/// priorities, protocols, and health scores.
class StreamSource extends Equatable {
  const StreamSource({
    required this.id,
    required this.channelId,
    required this.name,
    required this.url,
    required this.protocol,
    this.priority = 0,
    this.isActive = true,
    this.timeoutSeconds = 15,
    this.healthScore = 100.0,
    this.lastSuccessfulPlayback,
    this.consecutiveFailures = 0,
    this.region,
    this.tags = const [],
  });

  final String id;
  final String channelId;
  final String name;
  final String url;
  final StreamProtocol protocol;
  final int priority;
  final bool isActive;
  final int timeoutSeconds;
  final double healthScore;
  final DateTime? lastSuccessfulPlayback;
  final int consecutiveFailures;
  final String? region;
  final List<String> tags;

  /// Whether this source is considered healthy based on its score.
  bool get isHealthy => healthScore >= 50.0 && consecutiveFailures < 3;

  /// Whether this source has been verified working recently.
  bool get isVerified => lastSuccessfulPlayback != null;

  StreamSource copyWith({
    String? id,
    String? channelId,
    String? name,
    String? url,
    StreamProtocol? protocol,
    int? priority,
    bool? isActive,
    int? timeoutSeconds,
    double? healthScore,
    DateTime? lastSuccessfulPlayback,
    int? consecutiveFailures,
    String? region,
    List<String>? tags,
  }) {
    return StreamSource(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      name: name ?? this.name,
      url: url ?? this.url,
      protocol: protocol ?? this.protocol,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      healthScore: healthScore ?? this.healthScore,
      lastSuccessfulPlayback:
          lastSuccessfulPlayback ?? this.lastSuccessfulPlayback,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      region: region ?? this.region,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [id, channelId, url];
}
