import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/favorite_item.dart';
import '../../domain/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl();
});

class FavoritesRepositoryImpl implements FavoritesRepository {
  Box<String> get _box => Hive.box<String>('favorites');

  @override
  Future<List<FavoriteItem>> getFavorites() async {
    final items = <FavoriteItem>[];
    for (final key in _box.keys) {
      final raw = _box.get(key as String);
      if (raw != null) {
        final map = json.decode(raw) as Map<String, dynamic>;
        items.add(FavoriteItem(
          channelId: map['channelId'] as String,
          addedAt: DateTime.parse(map['addedAt'] as String),
          sortOrder: map['sortOrder'] as int? ?? 0,
        ));
      }
    }
    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  @override
  Future<bool> isFavorite(String channelId) async {
    return _box.containsKey(channelId);
  }

  @override
  Future<void> addFavorite(String channelId) async {
    final item = {
      'channelId': channelId,
      'addedAt': DateTime.now().toIso8601String(),
      'sortOrder': 0,
    };
    await _box.put(channelId, json.encode(item));
  }

  @override
  Future<void> removeFavorite(String channelId) async {
    await _box.delete(channelId);
  }

  @override
  Future<void> clearFavorites() async {
    await _box.clear();
  }
}
