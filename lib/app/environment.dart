/// Environment configuration for OzaIPTV.
///
/// Manages API base URLs, feature flags, and build-specific
/// configuration across development, staging, and production.
enum Environment {
  development,
  staging,
  production;

  String get apiBaseUrl => switch (this) {
        Environment.development => 'http://localhost:8080/api/v1',
        Environment.staging => 'https://staging-api.ozaiptv.com/api/v1',
        Environment.production => 'https://api.ozaiptv.com/api/v1',
      };

  String get name => switch (this) {
        Environment.development => 'Development',
        Environment.staging => 'Staging',
        Environment.production => 'Production',
      };

  bool get isDev => this == Environment.development;
  bool get isStaging => this == Environment.staging;
  bool get isProd => this == Environment.production;

  bool get enableDiagnostics => !isProd;
  bool get enableMockData => isDev;
  bool get enableAnalytics => isProd;
  bool get verboseLogging => isDev;
}

class EnvironmentConfig {
  const EnvironmentConfig._();

  static Environment _current = Environment.development;

  static Environment get current => _current;

  static void initialize(Environment env) {
    _current = env;
  }

  static String get apiBaseUrl => _current.apiBaseUrl;
  static bool get isDev => _current.isDev;
  static bool get isProd => _current.isProd;
  static bool get enableMockData => _current.enableMockData;
  static bool get enableDiagnostics => _current.enableDiagnostics;
  static bool get verboseLogging => _current.verboseLogging;

  /// App-level constants
  static const String appName = 'OzaIPTV';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  /// Playback constants
  static const int streamTimeoutSeconds = 15;
  static const int maxFallbackAttempts = 4;
  static const int healthCheckIntervalSeconds = 30;
  static const int bufferRetryDelayMs = 2000;

  /// Cache constants
  static const int maxCacheAgeMinutes = 60;
  static const int maxChannelCacheCount = 500;
  static const int maxHistoryItems = 100;
  static const int maxRecentSearches = 20;
}
