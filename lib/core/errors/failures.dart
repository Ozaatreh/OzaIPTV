/// Typed failure classes for clean error handling across layers.
abstract class AppFailure {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Server error occurred']);
  final int? statusCode = null;
}

class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class PlaybackFailure extends AppFailure {
  const PlaybackFailure([super.message = 'Playback error occurred']);
}

class ParseFailure extends AppFailure {
  const ParseFailure([super.message = 'Failed to parse data']);
}

class AuthFailure extends AppFailure {
  const AuthFailure([super.message = 'Authentication failed']);
}
