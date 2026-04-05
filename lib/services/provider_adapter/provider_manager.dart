import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/channel.dart';
import '../../domain/entities/channel_category.dart';
import 'iptv_provider_adapter.dart';
import 'm3u_provider_adapter.dart';
import 'xtream_provider_adapter.dart';

final providerManagerProvider = Provider<ProviderManager>(
  (ref) => ProviderManager(),
);

/// Manages multiple IPTV provider adapters and merges their
/// channels into the app's unified channel list.
///
/// Providers are persisted in Hive and loaded on startup.
class ProviderManager {
  final _logger = Logger(printer: SimplePrinter());
  final Map<String, IptvProviderAdapter> _adapters = {};
  final Map<String, ProviderHealthStatus> _healthStatus = {};

  Box<String> get _box => Hive.box<String>('cache');

  /// Get all registered adapters.
  List<IptvProviderAdapter> get adapters => _adapters.values.toList();

  /// Get health status for a provider.
  ProviderHealthStatus? getHealth(String providerId) =>
      _healthStatus[providerId];

  /// Add a new IPTV provider.
  Future<ProviderValidationResult> addProvider(
    IptvProviderConfig config,
  ) async {
    final adapter = _createAdapter(config);
    final result = await adapter.validate();

    if (result.isValid) {
      _adapters[config.id] = adapter;
      _healthStatus[config.id] = ProviderHealthStatus(
        providerId: config.id,
        isHealthy: true,
        lastChecked: DateTime.now(),
        channelCount: result.channelCount ?? 0,
        message: result.message,
      );

      // Persist config
      await _box.put(
        'provider_${config.id}',
        json.encode(_configToJson(config)),
      );

      _logger.i('Provider added: ${config.name} (${config.type.displayName})');
    } else {
      adapter.dispose();
      _healthStatus[config.id] = ProviderHealthStatus(
        providerId: config.id,
        isHealthy: false,
        lastChecked: DateTime.now(),
        channelCount: 0,
        message: result.message,
      );
    }

    return result;
  }

  /// Remove a provider.
  Future<void> removeProvider(String providerId) async {
    _adapters[providerId]?.dispose();
    _adapters.remove(providerId);
    _healthStatus.remove(providerId);
    await _box.delete('provider_$providerId');
    _logger.i('Provider removed: $providerId');
  }

  /// Fetch channels from all healthy providers.
  Future<List<Channel>> fetchAllChannels() async {
    final allChannels = <Channel>[];

    for (final entry in _adapters.entries) {
      try {
        final channels = await entry.value.fetchChannels();
        allChannels.addAll(channels);

        _healthStatus[entry.key] = ProviderHealthStatus(
          providerId: entry.key,
          isHealthy: true,
          lastChecked: DateTime.now(),
          channelCount: channels.length,
          message: '${channels.length} channels loaded',
        );
      } catch (e) {
        _logger.e('Provider ${entry.key} fetch failed: $e');
        _healthStatus[entry.key] = ProviderHealthStatus(
          providerId: entry.key,
          isHealthy: false,
          lastChecked: DateTime.now(),
          channelCount: 0,
          message: 'Fetch failed: $e',
        );
      }
    }

    return allChannels;
  }

  /// Fetch categories from all providers.
  Future<List<ChannelCategory>> fetchAllCategories() async {
    final allCategories = <ChannelCategory>[];
    final seenIds = <String>{};

    for (final adapter in _adapters.values) {
      try {
        final categories = await adapter.fetchCategories();
        for (final cat in categories) {
          if (!seenIds.contains(cat.id)) {
            seenIds.add(cat.id);
            allCategories.add(cat);
          }
        }
      } catch (_) {}
    }

    return allCategories;
  }

  /// Refresh health status for all providers.
  Future<void> refreshHealth() async {
    for (final entry in _adapters.entries) {
      try {
        final result = await entry.value.validate();
        _healthStatus[entry.key] = ProviderHealthStatus(
          providerId: entry.key,
          isHealthy: result.isValid,
          lastChecked: DateTime.now(),
          channelCount: result.channelCount ?? 0,
          message: result.message,
        );
      } catch (e) {
        _healthStatus[entry.key] = ProviderHealthStatus(
          providerId: entry.key,
          isHealthy: false,
          lastChecked: DateTime.now(),
          channelCount: 0,
          message: 'Health check failed: $e',
        );
      }
    }
  }

  /// Load persisted provider configs from Hive.
  Future<void> loadPersistedProviders() async {
    for (final key in _box.keys) {
      if (!(key as String).startsWith('provider_')) continue;
      final raw = _box.get(key);
      if (raw == null) continue;

      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        final config = _configFromJson(map);
        if (config.isEnabled) {
          final adapter = _createAdapter(config);
          _adapters[config.id] = adapter;
          _logger.d('Loaded provider: ${config.name}');
        }
      } catch (e) {
        _logger.e('Failed to load provider $key: $e');
      }
    }
  }

  // ── Factory ────────────────────────────────────────────────

  IptvProviderAdapter _createAdapter(IptvProviderConfig config) {
    return switch (config.type) {
      IptvProviderType.m3u => M3uProviderAdapter(config: config),
      IptvProviderType.xtream => XtreamProviderAdapter(config: config),
      IptvProviderType.customApi => M3uProviderAdapter(config: config),
    };
  }

  Map<String, dynamic> _configToJson(IptvProviderConfig c) => {
        'id': c.id,
        'name': c.name,
        'type': c.type.name,
        'url': c.url,
        'username': c.username,
        'password': c.password,
        'epgUrl': c.epgUrl,
        'userAgent': c.userAgent,
        'isEnabled': c.isEnabled,
        'addedAt': (c.addedAt ?? DateTime.now()).toIso8601String(),
      };

  IptvProviderConfig _configFromJson(Map<String, dynamic> m) =>
      IptvProviderConfig(
        id: m['id'] as String,
        name: m['name'] as String,
        type: IptvProviderType.values.firstWhere(
          (t) => t.name == m['type'],
          orElse: () => IptvProviderType.m3u,
        ),
        url: m['url'] as String?,
        username: m['username'] as String?,
        password: m['password'] as String?,
        epgUrl: m['epgUrl'] as String?,
        userAgent: m['userAgent'] as String?,
        isEnabled: m['isEnabled'] as bool? ?? true,
        addedAt: DateTime.tryParse(m['addedAt'] as String? ?? ''),
      );
}

class ProviderHealthStatus {
  const ProviderHealthStatus({
    required this.providerId,
    required this.isHealthy,
    required this.lastChecked,
    required this.channelCount,
    required this.message,
  });

  final String providerId;
  final bool isHealthy;
  final DateTime lastChecked;
  final int channelCount;
  final String message;
}
