import 'package:flutter_test/flutter_test.dart';
import 'package:ozaiptv/core/enums/stream_protocol.dart';
import 'package:ozaiptv/services/m3u/m3u_parser.dart';

void main() {
  late M3uParser parser;

  setUp(() {
    parser = M3uParser();
  });

  group('M3uParser', () {
    test('parses basic M3U playlist', () {
      const m3u = '''
#EXTM3U
#EXTINF:-1 tvg-id="BBCOne" tvg-logo="https://example.com/bbc.png" group-title="UK",BBC One
https://stream.bbc.co.uk/live.m3u8
#EXTINF:-1 tvg-id="CNN" group-title="News",CNN International
https://stream.cnn.com/live.m3u8
''';

      final channels = parser.parse(m3u);
      expect(channels, hasLength(2));
      expect(channels[0].name, equals('BBC One'));
      expect(channels[0].streamSources.first.protocol, equals(StreamProtocol.hls));
      expect(channels[1].name, equals('CNN International'));
    });

    test('handles empty playlist', () {
      final channels = parser.parse('');
      expect(channels, isEmpty);
    });

    test('handles playlist with only header', () {
      final channels = parser.parse('#EXTM3U');
      expect(channels, isEmpty);
    });

    test('extracts logo URL from attributes', () {
      const m3u = '''
#EXTM3U
#EXTINF:-1 tvg-logo="https://logo.com/img.png",Test Channel
https://stream.test.com/live.m3u8
''';

      final channels = parser.parse(m3u);
      expect(channels.first.logoUrl, equals('https://logo.com/img.png'));
    });

    test('normalizes category IDs', () {
      const m3u = '''
#EXTM3U
#EXTINF:-1 group-title="Sports & News",Test
https://example.com/test.m3u8
''';

      final channels = parser.parse(m3u);
      expect(channels.first.categoryId, equals('cat_sports___news'));
    });

    test('infers protocol from URL', () {
      const m3u = '''
#EXTM3U
#EXTINF:-1,HLS Channel
https://example.com/stream.m3u8
#EXTINF:-1,DASH Channel
https://example.com/stream.mpd
#EXTINF:-1,MP4 Channel
https://example.com/video.mp4
''';

      final channels = parser.parse(m3u);
      expect(channels[0].streamSources.first.protocol, StreamProtocol.hls);
      expect(channels[1].streamSources.first.protocol, StreamProtocol.dash);
      expect(channels[2].streamSources.first.protocol, StreamProtocol.progressive);
    });
  });
}
