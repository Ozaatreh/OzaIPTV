import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/channel_repository_impl.dart';
import '../data/repositories/epg_repository_impl.dart';
import '../data/repositories/favorites_repository_impl.dart';
import '../data/repositories/history_repository_impl.dart';
import '../domain/entities/channel.dart';
import '../domain/entities/channel_category.dart';
import '../domain/entities/epg_program.dart';
import '../domain/entities/favorite_item.dart';
import '../domain/entities/watch_history_item.dart';

// ── Channel providers ────────────────────────────────────────

final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  final repo = ref.watch(channelRepositoryProvider);
  return repo.getChannels();
});

final categoriesProvider = FutureProvider<List<ChannelCategory>>((ref) async {
  final repo = ref.watch(channelRepositoryProvider);
  return repo.getCategories();
});

final channelsByCategoryProvider =
    FutureProvider.family<List<Channel>, String>((ref, categoryId) async {
  final repo = ref.watch(channelRepositoryProvider);
  return repo.getChannelsByCategory(categoryId);
});

final channelByIdProvider =
    FutureProvider.family<Channel?, String>((ref, id) async {
  final repo = ref.watch(channelRepositoryProvider);
  return repo.getChannelById(id);
});

final searchResultsProvider =
    FutureProvider.family<List<Channel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.watch(channelRepositoryProvider);
  return repo.searchChannels(query);
});

// ── EPG providers ────────────────────────────────────────────

final currentProgramProvider =
    FutureProvider.family<EpgProgram?, String>((ref, channelId) async {
  final repo = ref.watch(epgRepositoryProvider);
  return repo.getCurrentProgram(channelId);
});

final channelProgramsProvider =
    FutureProvider.family<List<EpgProgram>, String>((ref, channelId) async {
  final repo = ref.watch(epgRepositoryProvider);
  return repo.getProgramsForChannel(channelId);
});

// ── Favorites providers ──────────────────────────────────────

final favoritesProvider = FutureProvider<List<FavoriteItem>>((ref) async {
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.getFavorites();
});

final isFavoriteProvider =
    FutureProvider.family<bool, String>((ref, channelId) async {
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.isFavorite(channelId);
});

// ── History providers ────────────────────────────────────────

final historyProvider = FutureProvider<List<WatchHistoryItem>>((ref) async {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.getHistory();
});
