import 'package:flutter_test/flutter_test.dart';
import 'package:ozaiptv/domain/entities/epg_program.dart';

void main() {
  group('EpgProgram', () {
    test('isCurrentlyAiring returns true for active program', () {
      final now = DateTime.now();
      final program = EpgProgram(
        id: 'p1',
        channelId: 'c1',
        title: 'Test Program',
        startTime: now.subtract(const Duration(minutes: 15)),
        endTime: now.add(const Duration(minutes: 45)),
      );

      expect(program.isCurrentlyAiring, isTrue);
      expect(program.isUpcoming, isFalse);
      expect(program.hasPassed, isFalse);
    });

    test('progress is between 0 and 1 for active program', () {
      final now = DateTime.now();
      final program = EpgProgram(
        id: 'p2',
        channelId: 'c1',
        title: 'Half Done',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.add(const Duration(minutes: 30)),
      );

      expect(program.progress, greaterThan(0.4));
      expect(program.progress, lessThan(0.6));
    });

    test('progress is 0 for upcoming program', () {
      final future = DateTime.now().add(const Duration(hours: 2));
      final program = EpgProgram(
        id: 'p3',
        channelId: 'c1',
        title: 'Future Program',
        startTime: future,
        endTime: future.add(const Duration(hours: 1)),
      );

      expect(program.progress, equals(0));
      expect(program.isUpcoming, isTrue);
    });

    test('progress is 1 for past program', () {
      final past = DateTime.now().subtract(const Duration(hours: 3));
      final program = EpgProgram(
        id: 'p4',
        channelId: 'c1',
        title: 'Past Program',
        startTime: past,
        endTime: past.add(const Duration(hours: 1)),
      );

      expect(program.progress, equals(1));
      expect(program.hasPassed, isTrue);
    });

    test('duration calculation', () {
      final start = DateTime(2026, 1, 1, 20, 0);
      final end = DateTime(2026, 1, 1, 21, 30);
      final program = EpgProgram(
        id: 'p5',
        channelId: 'c1',
        title: 'Long Show',
        startTime: start,
        endTime: end,
      );

      expect(program.duration.inMinutes, equals(90));
    });
  });
}
