/// Backend API contract definitions for OzaIPTV.
///
/// These define the expected request/response shapes for
/// future backend integration. No server is implemented.
library;

// ── Auth ─────────────────────────────────────────────────────

class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.expiresIn,
  });
  final String accessToken;
  final String refreshToken;
  final String userId;
  final int expiresIn;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      userId: json['user_id'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }
}

class RefreshTokenRequest {
  const RefreshTokenRequest({required this.refreshToken});
  final String refreshToken;

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}

// ── Channels ─────────────────────────────────────────────────

class ChannelsResponse {
  const ChannelsResponse({required this.channels, required this.total});
  final List<Map<String, dynamic>> channels;
  final int total;
}

class ChannelDetailResponse {
  const ChannelDetailResponse({required this.channel});
  final Map<String, dynamic> channel;
}

// ── Favorites ────────────────────────────────────────────────

class AddFavoriteRequest {
  const AddFavoriteRequest({required this.channelId});
  final String channelId;

  Map<String, dynamic> toJson() => {'channel_id': channelId};
}

// ── Playback Report ──────────────────────────────────────────

class PlaybackReportRequest {
  const PlaybackReportRequest({
    required this.channelId,
    required this.sourceId,
    required this.event,
    required this.durationSeconds,
    this.errorMessage,
  });

  final String channelId;
  final String sourceId;
  final String event; // 'start', 'stop', 'error', 'fallback'
  final int durationSeconds;
  final String? errorMessage;

  Map<String, dynamic> toJson() => {
        'channel_id': channelId,
        'source_id': sourceId,
        'event': event,
        'duration_seconds': durationSeconds,
        if (errorMessage != null) 'error_message': errorMessage,
      };
}

// ── Diagnostics Report ───────────────────────────────────────

class DiagnosticsReportRequest {
  const DiagnosticsReportRequest({
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
    required this.platform,
    required this.playerState,
    this.currentChannelId,
    this.currentSourceId,
    this.fallbackCount = 0,
    this.retryCount = 0,
    this.lastError,
  });

  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final String platform;
  final String playerState;
  final String? currentChannelId;
  final String? currentSourceId;
  final int fallbackCount;
  final int retryCount;
  final String? lastError;

  Map<String, dynamic> toJson() => {
        'device_model': deviceModel,
        'os_version': osVersion,
        'app_version': appVersion,
        'platform': platform,
        'player_state': playerState,
        if (currentChannelId != null) 'current_channel_id': currentChannelId,
        if (currentSourceId != null) 'current_source_id': currentSourceId,
        'fallback_count': fallbackCount,
        'retry_count': retryCount,
        if (lastError != null) 'last_error': lastError,
      };
}

/// API endpoint reference (documentation only).
///
/// POST   /api/v1/auth/login          → LoginResponse
/// POST   /api/v1/auth/refresh        → LoginResponse
/// GET    /api/v1/channels            → ChannelsResponse
/// GET    /api/v1/channels/{id}       → ChannelDetailResponse
/// GET    /api/v1/categories          → List<Category>
/// GET    /api/v1/epg?channel_id=X    → List<EpgProgram>
/// GET    /api/v1/favorites           → List<FavoriteItem>
/// POST   /api/v1/favorites           → void
/// DELETE /api/v1/favorites/{id}      → void
/// GET    /api/v1/history             → List<WatchHistoryItem>
/// POST   /api/v1/history             → void
/// POST   /api/v1/playback/report     → void
/// POST   /api/v1/diagnostics/report  → void
