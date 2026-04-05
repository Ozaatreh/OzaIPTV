import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/channel.dart';
import '../../domain/entities/channel_category.dart';
import '../../domain/repositories/channel_repository.dart';
import '../datasources/mock_channel_datasource.dart';

final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  return ChannelRepositoryImpl(ref.watch(mockChannelDataSourceProvider));
});

class ChannelRepositoryImpl implements ChannelRepository {
  ChannelRepositoryImpl(this._dataSource);

  final MockChannelDataSource _dataSource;

  @override
  Future<List<Channel>> getChannels() => _dataSource.getChannels();

  @override
  Future<Channel?> getChannelById(String id) =>
      _dataSource.getChannelById(id);

  @override
  Future<List<Channel>> getChannelsByCategory(String categoryId) =>
      _dataSource.getChannelsByCategory(categoryId);

  @override
  Future<List<Channel>> searchChannels(String query) =>
      _dataSource.searchChannels(query);

  @override
  Future<List<ChannelCategory>> getCategories() =>
      _dataSource.getCategories();
}
