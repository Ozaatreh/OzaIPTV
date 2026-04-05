abstract final class RouteNames {
  static const String splash = 'splash';
  static const String home = 'home';
  static const String liveTv = 'live-tv';
  static const String player = 'player';
  static const String search = 'search';
  static const String favorites = 'favorites';
  static const String history = 'history';
  static const String epg = 'epg';
  static const String settings = 'settings';
  static const String diagnostics = 'diagnostics';
}

abstract final class RoutePaths {
  static const String splash = '/';
  static const String home = '/home';
  static const String liveTv = '/live-tv';
  static const String player = '/player/:channelId';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String history = '/history';
  static const String epg = '/epg';
  static const String settings = '/settings';
  static const String diagnostics = '/settings/diagnostics';
}
