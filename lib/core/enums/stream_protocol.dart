/// Supported stream protocols for playback.
enum StreamProtocol {
  hls,
  dash,
  progressive,
  unknown;

  String get displayName => switch (this) {
        StreamProtocol.hls => 'HLS',
        StreamProtocol.dash => 'DASH',
        StreamProtocol.progressive => 'Progressive',
        StreamProtocol.unknown => 'Unknown',
      };

  /// Infer protocol from a URL.
  static StreamProtocol fromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('/hls')) {
      return StreamProtocol.hls;
    }
    if (lower.contains('.mpd') || lower.contains('/dash')) {
      return StreamProtocol.dash;
    }
    if (lower.contains('.mp4') || lower.contains('.ts')) {
      return StreamProtocol.progressive;
    }
    return StreamProtocol.unknown;
  }
}
