import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/stream_protocol.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/channel_category.dart';
import '../../domain/entities/stream_source.dart';

final mockChannelDataSourceProvider = Provider<MockChannelDataSource>((ref) {
  return MockChannelDataSource();
});

class MockChannelDataSource {
  List<Channel>? _cachedChannels;
  List<ChannelCategory>? _cachedCategories;

  Future<Map<String, dynamic>> _loadMockData() async {
    final jsonString = await rootBundle.loadString('assets/mock/channels.json');
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  Future<List<ChannelCategory>> getCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;

    final data = await _loadMockData();
    final categoriesList = data['categories'] as List<dynamic>;

    _cachedCategories = categoriesList.map((c) {
      final map = c as Map<String, dynamic>;
      return ChannelCategory(
        id: map['id'] as String,
        name: map['name'] as String,
        iconName: map['iconName'] as String?,
        sortOrder: map['sortOrder'] as int? ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return _cachedCategories!;
  }

  Future<List<Channel>> getChannels() async {
    if (_cachedChannels != null) return _cachedChannels!;

    final data = await _loadMockData();
    final channelsList = data['channels'] as List<dynamic>;

    _cachedChannels = channelsList.map((ch) {
      final map = ch as Map<String, dynamic>;
      final sourcesRaw = map['streamSources'] as List<dynamic>? ?? [];
      final sources = sourcesRaw.map((s) {
        final sm = s as Map<String, dynamic>;
        return StreamSource(
          id: sm['id'] as String,
          channelId: sm['channelId'] as String,
          name: sm['name'] as String,
          url: sm['url'] as String,
          protocol: StreamProtocol.values.firstWhere(
            (p) => p.name == (sm['protocol'] as String),
            orElse: () => StreamProtocol.unknown,
          ),
          priority: sm['priority'] as int? ?? 0,
          isActive: sm['isActive'] as bool? ?? true,
          timeoutSeconds: sm['timeoutSeconds'] as int? ?? 15,
          healthScore: (sm['healthScore'] as num?)?.toDouble() ?? 100,
          region: sm['region'] as String?,
        );
      }).toList();

      final tagsRaw = map['tags'] as List<dynamic>? ?? [];
      final tags = tagsRaw.map((t) => t as String).toList();

      return Channel(
        id: map['id'] as String,
        name: map['name'] as String,
        categoryId: map['categoryId'] as String,
        logoUrl: map['logoUrl'] as String?,
        description: map['description'] as String?,
        country: map['country'] as String?,
        language: map['language'] as String?,
        streamSources: sources,
        tags: tags,
      );
    }).toList();

    return _cachedChannels!;
  }

  Future<Channel?> getChannelById(String id) async {
    final channels = await getChannels();
    try {
      return channels.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Channel>> getChannelsByCategory(String categoryId) async {
    final channels = await getChannels();
    return channels.where((c) => c.categoryId == categoryId).toList();
  }

  Future<List<Channel>> searchChannels(String query) async {
    final channels = await getChannels();
    final lower = query.toLowerCase();
    return channels.where((c) {
      return c.name.toLowerCase().contains(lower) ||
          (c.description?.toLowerCase().contains(lower) ?? false) ||
          c.tags.any((t) => t.toLowerCase().contains(lower));
    }).toList();
  }

  void clearCache() {
    _cachedChannels = null;
    _cachedCategories = null;
  }
}
