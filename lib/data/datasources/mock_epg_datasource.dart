import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/epg_program.dart';

final mockEpgDataSourceProvider = Provider<MockEpgDataSource>((ref) {
  return MockEpgDataSource();
});

class MockEpgDataSource {
  List<EpgProgram>? _cachedPrograms;

  Future<List<EpgProgram>> _loadPrograms() async {
    if (_cachedPrograms != null) return _cachedPrograms!;

    final jsonString = await rootBundle.loadString('assets/mock/epg.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final programsList = data['programs'] as List<dynamic>;
    final now = DateTime.now();

    _cachedPrograms = programsList.map((p) {
      final map = p as Map<String, dynamic>;
      final offsetMinutes = map['startTimeOffset'] as int;
      final durationMinutes = map['durationMinutes'] as int;
      final start = now.add(Duration(minutes: offsetMinutes));
      final end = start.add(Duration(minutes: durationMinutes));

      return EpgProgram(
        id: map['id'] as String,
        channelId: map['channelId'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        category: map['category'] as String?,
        startTime: start,
        endTime: end,
        isLive: start.isBefore(now) && end.isAfter(now),
      );
    }).toList();

    return _cachedPrograms!;
  }

  Future<List<EpgProgram>> getProgramsForChannel(String channelId) async {
    final all = await _loadPrograms();
    return all.where((p) => p.channelId == channelId).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<EpgProgram?> getCurrentProgram(String channelId) async {
    final programs = await getProgramsForChannel(channelId);
    final now = DateTime.now();
    try {
      return programs.firstWhere(
        (p) => p.startTime.isBefore(now) && p.endTime.isAfter(now),
      );
    } catch (_) {
      return null;
    }
  }

  Future<EpgProgram?> getNextProgram(String channelId) async {
    final programs = await getProgramsForChannel(channelId);
    final now = DateTime.now();
    try {
      return programs.firstWhere((p) => p.startTime.isAfter(now));
    } catch (_) {
      return null;
    }
  }
}
