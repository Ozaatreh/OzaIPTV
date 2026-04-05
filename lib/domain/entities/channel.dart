import 'package:equatable/equatable.dart';

import 'stream_source.dart';

/// Core domain entity representing a TV channel.
class Channel extends Equatable {
  const Channel({
    required this.id,
    required this.name,
    required this.categoryId,
    this.logoUrl,
    this.description,
    this.country,
    this.language,
    this.streamSources = const [],
    this.tags = const [],
    this.isFavorite = false,
    this.isLive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String categoryId;
  final String? logoUrl;
  final String? description;
  final String? country;
  final String? language;
  final List<StreamSource> streamSources;
  final List<String> tags;
  final bool isFavorite;
  final bool isLive;
  final int sortOrder;

  /// Returns the highest-priority active stream source.
  StreamSource? get primarySource {
    final activeSources = streamSources
        .where((s) => s.isActive)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return activeSources.isNotEmpty ? activeSources.first : null;
  }

  /// Returns all active stream sources sorted by priority.
  List<StreamSource> get activeSources => streamSources
      .where((s) => s.isActive)
      .toList()
    ..sort((a, b) => a.priority.compareTo(b.priority));

  /// Returns the number of available backup sources.
  int get backupSourceCount =>
      activeSources.length > 1 ? activeSources.length - 1 : 0;

  Channel copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? logoUrl,
    String? description,
    String? country,
    String? language,
    List<StreamSource>? streamSources,
    List<String>? tags,
    bool? isFavorite,
    bool? isLive,
    int? sortOrder,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      country: country ?? this.country,
      language: language ?? this.language,
      streamSources: streamSources ?? this.streamSources,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isLive: isLive ?? this.isLive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [id, name, categoryId];
}
