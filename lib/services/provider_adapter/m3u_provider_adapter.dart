import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:ozaiptv/domain/entities/epg_program.dart';

import '../../core/enums/stream_protocol.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/channel_category.dart';
import '../../domain/entities/stream_source.dart';
import 'iptv_provider_adapter.dart';

/// Adapter that fetches and parses M3U/M3U8 playlists from a URL
/// or local file, converting entries into OzaIPTV Channel models.
class M3uProviderAdapter implements IptvProviderAdapter {
  M3uProviderAdapter({required this.config, Dio? dio})
      : _dio = dio ?? Dio();

  final IptvProviderConfig config;
  final Dio _dio;
  final _logger = Logger(printer: SimplePrinter());

  List<Channel>? _cachedChannels;
  List<ChannelCategory>? _cachedCategories;

  @override
  String get providerId => config.id;

  @override
  String get providerName => config.name;

  @override
  IptvProviderType get type => IptvProviderType.m3u;

  @override
  Future<bool> get isHealthy async {
    try {
      final result = await validate();
      return result.isValid;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ProviderValidationResult> validate() async {
    if (config.url == null || config.url!.isEmpty) {
      return const ProviderValidationResult(
        isValid: false,
        message: 'No M3U URL configured',
      );
    }

    final sw = Stopwatch()..start();
    try {
      final content = await _fetchPlaylist();
      sw.stop();
      final channels = _parse(content);
      final categories = _extractCategories(channels);

      return ProviderValidationResult(
        isValid: channels.isNotEmpty,
        message: channels.isEmpty
            ? 'Playlist is empty'
            : 'Found ${channels.length} channels',
        channelCount: channels.length,
        categoryCount: categories.length,
        latencyMs: sw.elapsedMilliseconds,
      );
    } catch (e) {
      sw.stop();
      return ProviderValidationResult(
        isValid: false,
        message: 'Failed: $e',
        latencyMs: sw.elapsedMilliseconds,
      );
    }
  }

  @override
  Future<List<Channel>> fetchChannels() async {
    if (_cachedChannels != null) return _cachedChannels!;
    final content = await _fetchPlaylist();
    _cachedChannels = _parse(content);
    _cachedCategories = _extractCategories(_cachedChannels!);
    _logger.i('M3U: parsed ${_cachedChannels!.length} channels');
    return _cachedChannels!;
  }

  @override
  Future<List<ChannelCategory>> fetchCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;
    await fetchChannels();
    return _cachedCategories ?? [];
  }

  @override
  void dispose() {
    _cachedChannels = null;
    _cachedCategories = null;
  }

  // ── Fetch ──────────────────────────────────────────────────

  Future<String> _fetchPlaylist() async {
    final url = config.url!;

    // Local file
    if (url.startsWith('/') || url.startsWith('file://')) {
      final path = url.replaceFirst('file://', '');
      return File(path).readAsString();
    }

    // Remote
    final response = await _dio.get<String>(
      url,
      options: Options(
        headers: {
          if (config.userAgent != null) 'User-Agent': config.userAgent!,
        },
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    if (response.data == null || response.data!.isEmpty) {
      throw Exception('Empty playlist response');
    }

    return response.data!;
  }

  // ── Parse ──────────────────────────────────────────────────

  List<Channel> _parse(String content) {
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

        // Find next URL
        i++;
        while (i < lines.length &&
            (lines[i].isEmpty || lines[i].startsWith('#'))) {
          i++;
        }
        if (i >= lines.length || lines[i].isEmpty) continue;

        final url = lines[i];
        final channelId = attrs['tvg-id'] ??
            '${config.id}_${channels.length}_${name.hashCode.abs()}';
        final groupTitle = attrs['group-title'] ?? 'Uncategorized';

        channels.add(Channel(
          id: channelId,
          name: name,
          categoryId: _normalizeCatId(groupTitle),
          logoUrl: attrs['tvg-logo'],
          language: attrs['tvg-language'],
          country: attrs['tvg-country'],
          description: 'From ${config.name}',
          tags: [config.name, if (groupTitle != 'Uncategorized') groupTitle],
          streamSources: [
            StreamSource(
              id: '${channelId}_src0',
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
    for (final match in regex.allMatches(line)) {
      attrs[match.group(1)!] = match.group(2)!;
    }
    return attrs;
  }

  String _parseName(String line) {
    final idx = line.lastIndexOf(',');
    if (idx >= 0 && idx < line.length - 1) {
      return line.substring(idx + 1).trim();
    }
    return 'Unknown Channel';
  }

  String _normalizeCatId(String group) {
    return 'cat_${group.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
  }

  List<ChannelCategory> _extractCategories(List<Channel> channels) {
    final catIds = <String>{};
    final categories = <ChannelCategory>[];

    for (final ch in channels) {
      if (!catIds.contains(ch.categoryId)) {
        catIds.add(ch.categoryId);
        categories.add(ChannelCategory(
          id: ch.categoryId,
          name: ch.categoryId
              .replaceFirst('cat_', '')
              .replaceAll('_', ' ')
              .split(' ')
              .map((w) => w.isEmpty
                  ? ''
                  : '${w[0].toUpperCase()}${w.substring(1)}')
              .join(' ')
              .trim(),
          sortOrder: categories.length,
          channelCount:
              channels.where((c) => c.categoryId == ch.categoryId).length,
        ));
      }
    }

    return categories;
  }

  @override
  Future<List<EpgProgram>> fetchEpg(String channelId) {
    // TODO: implement fetchEpg
    throw UnimplementedError();
  }
}
