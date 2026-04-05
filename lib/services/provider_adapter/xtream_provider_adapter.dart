import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../core/enums/stream_protocol.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/channel_category.dart';
import '../../domain/entities/epg_program.dart';
import '../../domain/entities/stream_source.dart';
import 'iptv_provider_adapter.dart';

/// Adapter for Xtream Codes API-compatible IPTV providers.
///
/// Xtream Codes API endpoints used:
///   GET {server}/player_api.php?username={u}&password={p}
///   GET {server}/player_api.php?username={u}&password={p}&action=get_live_categories
///   GET {server}/player_api.php?username={u}&password={p}&action=get_live_streams
///   GET {server}/player_api.php?username={u}&password={p}&action=get_short_epg&stream_id={id}
///   Stream URL: {server}/{u}/{p}/{stream_id}
class XtreamProviderAdapter implements IptvProviderAdapter {
  XtreamProviderAdapter({required this.config, Dio? dio})
      : _dio = dio ?? Dio();

  final IptvProviderConfig config;
  final Dio _dio;
  final _logger = Logger(printer: SimplePrinter());

  List<Channel>? _cachedChannels;
  List<ChannelCategory>? _cachedCategories;
  Map<String, dynamic>? _serverInfo;

  @override
  String get providerId => config.id;

  @override
  String get providerName => config.name;

  @override
  IptvProviderType get type => IptvProviderType.xtream;

  String get _baseUrl => config.url ?? '';
  String get _username => config.username ?? '';
  String get _password => config.password ?? '';

  String _apiUrl([String? action]) {
    final base = '$_baseUrl/player_api.php?username=$_username&password=$_password';
    if (action != null) return '$base&action=$action';
    return base;
  }

  @override
  Future<bool> get isHealthy async {
    try {
      final r = await validate();
      return r.isValid;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ProviderValidationResult> validate() async {
    if (_baseUrl.isEmpty || _username.isEmpty || _password.isEmpty) {
      return const ProviderValidationResult(
        isValid: false,
        message: 'Missing server URL, username, or password',
      );
    }

    final sw = Stopwatch()..start();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _apiUrl(),
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );
      sw.stop();

      final data = response.data;
      if (data == null) {
        return ProviderValidationResult(
          isValid: false,
          message: 'Empty server response',
          latencyMs: sw.elapsedMilliseconds,
        );
      }

      _serverInfo = data['server_info'] as Map<String, dynamic>?;
      final userInfo = data['user_info'] as Map<String, dynamic>?;
      final isActive = userInfo?['status'] == 'Active';

      if (!isActive) {
        return ProviderValidationResult(
          isValid: false,
          message: 'Account inactive or expired',
          latencyMs: sw.elapsedMilliseconds,
          serverInfo: _serverInfo?['server_protocol'] as String?,
        );
      }

      return ProviderValidationResult(
        isValid: true,
        message: 'Connected — ${userInfo?['status']}',
        latencyMs: sw.elapsedMilliseconds,
        serverInfo: _serverInfo.toString(),
      );
    } on DioException catch (e) {
      sw.stop();
      return ProviderValidationResult(
        isValid: false,
        message: 'Connection failed: ${e.message}',
        latencyMs: sw.elapsedMilliseconds,
      );
    } catch (e) {
      sw.stop();
      return ProviderValidationResult(
        isValid: false,
        message: 'Error: $e',
        latencyMs: sw.elapsedMilliseconds,
      );
    }
  }

  @override
  Future<List<ChannelCategory>> fetchCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;

    try {
      final response = await _dio.get<List<dynamic>>(
        _apiUrl('get_live_categories'),
      );
      final data = response.data ?? [];

      _cachedCategories = data.asMap().entries.map((entry) {
        final cat = entry.value as Map<String, dynamic>;
        return ChannelCategory(
          id: 'xt_cat_${cat['category_id']}',
          name: cat['category_name'] as String? ?? 'Unknown',
          sortOrder: entry.key,
          channelCount: 0,
        );
      }).toList();

      _logger.i('Xtream: ${_cachedCategories!.length} categories');
      return _cachedCategories!;
    } catch (e) {
      _logger.e('Xtream categories error: $e');
      return [];
    }
  }

  @override
  Future<List<Channel>> fetchChannels() async {
    if (_cachedChannels != null) return _cachedChannels!;

    try {
      final response = await _dio.get<List<dynamic>>(
        _apiUrl('get_live_streams'),
      );
      final data = response.data ?? [];

      _cachedChannels = data.map((item) {
        final stream = item as Map<String, dynamic>;
        final streamId = stream['stream_id']?.toString() ?? '';
        final channelId = 'xt_${config.id}_$streamId';
        final catId = 'xt_cat_${stream['category_id']}';

        // Build stream URL: server/username/password/streamId
        final streamUrl = '$_baseUrl/$_username/$_password/$streamId';

        return Channel(
          id: channelId,
          name: stream['name'] as String? ?? 'Unknown',
          categoryId: catId,
          logoUrl: stream['stream_icon'] as String?,
          description: 'From ${config.name}',
          country: stream['tv_archive']?.toString(),
          language: null,
          tags: [config.name],
          streamSources: [
            StreamSource(
              id: '${channelId}_src0',
              channelId: channelId,
              name: 'Xtream Live',
              url: streamUrl,
              protocol: StreamProtocol.hls,
              priority: 0,
            ),
            // Also add .m3u8 variant as backup
            StreamSource(
              id: '${channelId}_src1',
              channelId: channelId,
              name: 'HLS Variant',
              url: '$_baseUrl/live/$_username/$_password/$streamId.m3u8',
              protocol: StreamProtocol.hls,
              priority: 1,
            ),
          ],
        );
      }).toList();

      _logger.i('Xtream: ${_cachedChannels!.length} channels');
      return _cachedChannels!;
    } catch (e) {
      _logger.e('Xtream channels error: $e');
      return [];
    }
  }

  @override
  Future<List<EpgProgram>> fetchEpg(String channelId) async {
    // Extract stream ID from our channel ID format
    final streamId = channelId.replaceFirst('xt_${config.id}_', '');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${_apiUrl('get_short_epg')}&stream_id=$streamId',
      );

      final data = response.data;
      if (data == null) return [];

      final listings = data['epg_listings'] as List<dynamic>? ?? [];

      return listings.map((item) {
        final epg = item as Map<String, dynamic>;
        final start = DateTime.tryParse(
                epg['start'] as String? ?? '') ??
            DateTime.now();
        final end =
            DateTime.tryParse(epg['end'] as String? ?? '') ??
                start.add(const Duration(hours: 1));

        return EpgProgram(
          id: 'xt_epg_${epg['id']}',
          channelId: channelId,
          title: epg['title'] as String? ?? 'Unknown',
          description: epg['description'] as String?,
          startTime: start,
          endTime: end,
        );
      }).toList();
    } catch (e) {
      _logger.e('Xtream EPG error: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _cachedChannels = null;
    _cachedCategories = null;
    _serverInfo = null;
  }
}
