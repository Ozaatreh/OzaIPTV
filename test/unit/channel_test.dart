import 'package:flutter_test/flutter_test.dart';
import 'package:ozaiptv/core/enums/stream_protocol.dart';
import 'package:ozaiptv/domain/entities/channel.dart';
import 'package:ozaiptv/domain/entities/stream_source.dart';

void main() {
  group('Channel', () {
    Channel _createChannel({
      List<StreamSource>? sources,
    }) {
      return Channel(
        id: 'ch_1',
        name: 'Test Channel',
        categoryId: 'cat_test',
        streamSources: sources ??
            [
              const StreamSource(
                id: 'src_0',
                channelId: 'ch_1',
                name: 'Primary',
                url: 'https://example.com/a.m3u8',
                protocol: StreamProtocol.hls,
                priority: 0,
                healthScore: 95,
              ),
              const StreamSource(
                id: 'src_1',
                channelId: 'ch_1',
                name: 'Backup',
                url: 'https://example.com/b.m3u8',
                protocol: StreamProtocol.hls,
                priority: 1,
                healthScore: 80,
              ),
              const StreamSource(
                id: 'src_2',
                channelId: 'ch_1',
                name: 'Disabled',
                url: 'https://example.com/c.m3u8',
                protocol: StreamProtocol.hls,
                priority: 2,
                isActive: false,
              ),
            ],
      );
    }

    test('primarySource returns highest-priority active source', () {
      final channel = _createChannel();
      expect(channel.primarySource, isNotNull);
      expect(channel.primarySource!.id, equals('src_0'));
    });

    test('activeSources excludes inactive sources', () {
      final channel = _createChannel();
      expect(channel.activeSources, hasLength(2));
      expect(channel.activeSources.any((s) => s.id == 'src_2'), isFalse);
    });

    test('backupSourceCount is correct', () {
      final channel = _createChannel();
      expect(channel.backupSourceCount, equals(1));
    });

    test('primarySource is null when no sources', () {
      final channel = _createChannel(sources: []);
      expect(channel.primarySource, isNull);
      expect(channel.backupSourceCount, equals(0));
    });

    test('copyWith preserves unchanged fields', () {
      final channel = _createChannel();
      final updated = channel.copyWith(name: 'Updated');
      expect(updated.name, equals('Updated'));
      expect(updated.id, equals(channel.id));
      expect(updated.streamSources, equals(channel.streamSources));
    });
  });

  group('StreamSource', () {
    test('isHealthy returns true for good sources', () {
      const source = StreamSource(
        id: 'src_1',
        channelId: 'ch_1',
        name: 'Good',
        url: 'https://example.com/stream.m3u8',
        protocol: StreamProtocol.hls,
        healthScore: 85,
        consecutiveFailures: 0,
      );
      expect(source.isHealthy, isTrue);
    });

    test('isHealthy returns false for degraded sources', () {
      const source = StreamSource(
        id: 'src_2',
        channelId: 'ch_1',
        name: 'Bad',
        url: 'https://example.com/stream.m3u8',
        protocol: StreamProtocol.hls,
        healthScore: 30,
        consecutiveFailures: 5,
      );
      expect(source.isHealthy, isFalse);
    });
  });

  group('StreamProtocol', () {
    test('fromUrl detects HLS', () {
      expect(
        StreamProtocol.fromUrl('https://cdn.com/live/stream.m3u8'),
        equals(StreamProtocol.hls),
      );
    });

    test('fromUrl detects DASH', () {
      expect(
        StreamProtocol.fromUrl('https://cdn.com/live/manifest.mpd'),
        equals(StreamProtocol.dash),
      );
    });

    test('fromUrl detects progressive', () {
      expect(
        StreamProtocol.fromUrl('https://cdn.com/video.mp4'),
        equals(StreamProtocol.progressive),
      );
    });

    test('fromUrl returns unknown for unsupported', () {
      expect(
        StreamProtocol.fromUrl('https://cdn.com/stream'),
        equals(StreamProtocol.unknown),
      );
    });
  });
}
