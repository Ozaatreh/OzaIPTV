import '../entities/channel.dart';
import '../entities/channel_category.dart';

abstract class ChannelRepository {
  Future<List<Channel>> getChannels();
  Future<Channel?> getChannelById(String id);
  Future<List<Channel>> getChannelsByCategory(String categoryId);
  Future<List<Channel>> searchChannels(String query);
  Future<List<ChannelCategory>> getCategories();
}
