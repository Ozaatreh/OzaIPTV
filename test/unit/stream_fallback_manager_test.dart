import 'package:flutter_test/flutter_test.dart';
import 'package:ozaiptv/core/enums/stream_protocol.dart';
import 'package:ozaiptv/domain/entities/channel.dart';
import 'package:ozaiptv/domain/entities/stream_source.dart';
import 'package:ozaiptv/services/playback/stream_fallback_manager.dart';

void main() {
  late StreamFallbackManager manager;

  setUp(() {
    manager = StreamFallbackManager();
  });

  Channel _createChannel({int sourceCount = 3}) {
    return Channel(
      id: 'test_channel',
      name: 'Test Channel',
      categoryId: 'cat_test',
      streamSources: List.generate(
        sourceCount,
        (i) => StreamSource(
          id: 'src_$i',
          channelId: 'test_channel',
          name: 'Source $i',
          url: 'https://example.com/stream_$i.m3u8',
          protocol: StreamProtocol.hls,
          priority: i,
          healthScore: 100.0 - (i * 10),
        ),
      ),
    );
  }

  group('StreamFallbackManager', () {
    test('initializes with first source selected', () {
      final channel = _createChannel();
      manager.initializeForChannel(channel);

      expect(manager.currentSource, isNotNull);
      expect(manager.currentSource!.id, equals('src_0'));
      expect(manager.hasMoreSources, isTrue);
      expect(manager.allSourcesExhausted, isFalse);
    });

    test('retries current source once before switching', () {
      final channel = _createChannel();
      manager.initializeForChannel(channel);

      // First failure: should retry same source
      final retry = manager.onSourceFailed(reason: 'timeout');
      expect(retry!.id, equals('src_0'));
      expect(manager.totalRetryCount, equals(1));
    });

    test('switches to next source after retry exhausted', () {
      final channel = _createChannel();
      manager.initializeForChannel(channel);

      // First failure: retry
      manager.onSourceFailed(reason: 'timeout');
      // Second failure: switch
      final next = manager.onSourceFailed(reason: 'timeout');
      expect(next!.id, equals('src_1'));
      expect(manager.fallbackCount, equals(1));
    });

    test('reports all exhausted when no more sources', () {
      final channel = _createChannel(sourceCount: 1);
      manager.initializeForChannel(channel);

      // Retry
      manager.onSourceFailed(reason: 'fail');
      // Exhaust
      final result = manager.onSourceFailed(reason: 'fail');
      expect(result, isNull);
      expect(manager.allSourcesExhausted, isTrue);
    });

    test('records success event', () {
      final channel = _createChannel();
      manager.initializeForChannel(channel);
      manager.onSourceSuccess();

      expect(manager.lastKnownWorkingSourceId, equals('src_0'));
      expect(
        manager.events.any((e) => e.type == FallbackEventType.success),
        isTrue,
      );
    });

    test('prefers last known working source', () {
      final channel = _createChannel();
      manager.initializeForChannel(
        channel,
        lastWorkingSourceId: 'src_2',
      );

      // src_2 should be moved to front
      expect(manager.currentSource!.id, equals('src_2'));
    });
  });
}
