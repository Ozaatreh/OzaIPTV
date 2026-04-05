import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/epg_program.dart';
import '../../domain/repositories/epg_repository.dart';
import '../datasources/mock_epg_datasource.dart';

final epgRepositoryProvider = Provider<EpgRepository>((ref) {
  return EpgRepositoryImpl(ref.watch(mockEpgDataSourceProvider));
});

class EpgRepositoryImpl implements EpgRepository {
  EpgRepositoryImpl(this._dataSource);

  final MockEpgDataSource _dataSource;

  @override
  Future<List<EpgProgram>> getProgramsForChannel(String channelId) =>
      _dataSource.getProgramsForChannel(channelId);

  @override
  Future<EpgProgram?> getCurrentProgram(String channelId) =>
      _dataSource.getCurrentProgram(channelId);

  @override
  Future<EpgProgram?> getNextProgram(String channelId) =>
      _dataSource.getNextProgram(channelId);

  @override
  Future<List<EpgProgram>> getProgramsInRange(
    String channelId,
    DateTime start,
    DateTime end,
  ) async {
    final programs = await _dataSource.getProgramsForChannel(channelId);
    return programs
        .where((p) => p.startTime.isBefore(end) && p.endTime.isAfter(start))
        .toList();
  }
}
