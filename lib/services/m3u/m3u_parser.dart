import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/stream_protocol.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/stream_source.dart';

final m3uParserProvider = Provider<M3uParser>((ref) => M3uParser());

/// Parses M3U/M3U8 playlists into Channel entities.
///
/// Supports extended M3U format with #EXTINF directives
/// and attributes: tvg-id, tvg-name, tvg-logo, group-title,
/// tvg-language, tvg-country.
class M3uParser {
  List<Channel> parse(String content, {String sourcePrefix = 'local'}) {
    final lines = content.split('\n').map((l) => l.trim()).toList();
    final channels = <Channel>[];
    if (lines.isEmpty) return channels;

    var i = 0;
    if (lines.first.startsWith('#EXTM3U')) i = 1;

    while (i < lines.length) {
      final line = lines[i];
      if (line.startsWith('#EXTINF:')) {
        final attrs = _parseAttrs(line);
        final name = _parseName(line);

        i++;
        while (i < lines.length &&
            (lines[i].isEmpty || lines[i].startsWith('#'))) {
          i++;
        }
        if (i >= lines.length || lines[i].isEmpty) continue;

        final url = lines[i];
        final channelId = attrs['tvg-id'] ??
            '${sourcePrefix}_${channels.length}_${name.hashCode.abs()}';

        channels.add(Channel(
          id: channelId,
          name: name,
          categoryId: _catId(attrs['group-title'] ?? 'Uncategorized'),
          logoUrl: attrs['tvg-logo'],
          language: attrs['tvg-language'],
          country: attrs['tvg-country'],
          streamSources: [
            StreamSource(
              id: 'src_${channelId}_0',
              channelId: channelId,
              name: 'Primary',
              url: url,
              protocol: StreamProtocol.fromUrl(url),
              priority: 0,
            ),
          ],
        ));
      }
      i++;
    }
    return channels;
  }

  Map<String, String> _parseAttrs(String line) {
    final attrs = <String, String>{};
    final regex = RegExp(r'(\w[\w-]*)="([^"]*)"');
    for (final m in regex.allMatches(line)) {
      attrs[m.group(1)!] = m.group(2)!;
    }
    return attrs;
  }

  String _parseName(String line) {
    final idx = line.lastIndexOf(',');
    if (idx >= 0 && idx < line.length - 1) return line.substring(idx + 1).trim();
    return 'Unknown Channel';
  }

  String _catId(String group) =>
      'cat_${group.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
}
