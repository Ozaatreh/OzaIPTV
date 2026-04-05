import '../entities/favorite_item.dart';

abstract class FavoritesRepository {
  Future<List<FavoriteItem>> getFavorites();
  Future<bool> isFavorite(String channelId);
  Future<void> addFavorite(String channelId);
  Future<void> removeFavorite(String channelId);
  Future<void> clearFavorites();
}
