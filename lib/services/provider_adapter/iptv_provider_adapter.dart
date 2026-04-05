import '../../domain/entities/channel.dart';
import '../../domain/entities/channel_category.dart';
import '../../domain/entities/epg_program.dart';

/// Abstract adapter that all IPTV providers must implement.
///
/// Converts external provider data (M3U, Xtream Codes, JSON API)
/// into OzaIPTV's internal Channel/StreamSource models.
abstract class IptvProviderAdapter {
  /// Unique identifier for this provider instance.
  String get providerId;

  /// Human-readable name.
  String get providerName;

  /// Provider type (m3u, xtream, custom_api).
  IptvProviderType get type;

  /// Whether this provider is currently connected and healthy.
  Future<bool> get isHealthy;

  /// Fetch all channels from this provider.
  Future<List<Channel>> fetchChannels();

  /// Fetch all categories from this provider.
  Future<List<ChannelCategory>> fetchCategories();

  /// Fetch EPG data for a channel (optional).
  Future<List<EpgProgram>> fetchEpg(String channelId) async => [];

  /// Validate the provider connection (API key, URL reachability, etc.)
  Future<ProviderValidationResult> validate();

  /// Dispose resources.
  void dispose();
}

enum IptvProviderType {
  m3u,
  xtream,
  customApi;

  String get displayName => switch (this) {
        IptvProviderType.m3u => 'M3U Playlist',
        IptvProviderType.xtream => 'Xtream Codes',
        IptvProviderType.customApi => 'Custom API',
      };
}

class ProviderValidationResult {
  const ProviderValidationResult({
    required this.isValid,
    required this.message,
    this.channelCount,
    this.categoryCount,
    this.latencyMs,
    this.serverInfo,
  });

  final bool isValid;
  final String message;
  final int? channelCount;
  final int? categoryCount;
  final int? latencyMs;
  final String? serverInfo;
}

/// Configuration for connecting to an IPTV provider.
class IptvProviderConfig {
  const IptvProviderConfig({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.username,
    this.password,
    this.epgUrl,
    this.userAgent,
    this.isEnabled = true,
    this.addedAt,
  });

  final String id;
  final String name;
  final IptvProviderType type;
  final String? url;
  final String? username;
  final String? password;
  final String? epgUrl;
  final String? userAgent;
  final bool isEnabled;
  final DateTime? addedAt;
}
