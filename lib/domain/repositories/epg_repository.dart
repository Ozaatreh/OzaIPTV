import '../entities/epg_program.dart';

abstract class EpgRepository {
  Future<List<EpgProgram>> getProgramsForChannel(String channelId);
  Future<EpgProgram?> getCurrentProgram(String channelId);
  Future<EpgProgram?> getNextProgram(String channelId);
  Future<List<EpgProgram>> getProgramsInRange(
    String channelId,
    DateTime start,
    DateTime end,
  );
}
