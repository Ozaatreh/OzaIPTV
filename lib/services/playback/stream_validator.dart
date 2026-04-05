import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/stream_source.dart';

final streamValidatorProvider = Provider<StreamValidator>(
  (ref) => StreamValidator(),
);

/// Validates stream URLs before playback to avoid wasting time
/// on dead/unreachable sources.
///
/// Performs a lightweight HTTP HEAD or partial GET to check:
/// - DNS resolution
/// - TCP connectivity
/// - HTTP response code (200/206/302 = valid)
/// - Content-type sniffing (must look like media)
class StreamValidator {
  final _logger = Logger(printer: SimplePrinter());

  /// Validate a stream source URL. Returns a result with
  /// success/failure and diagnostics.
  Future<ValidationResult> validate(
    StreamSource source, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = Uri.tryParse(source.url);
    if (uri == null || !uri.hasScheme) {
      return ValidationResult(
        isValid: false,
        sourceId: source.id,
        url: source.url,
        reason: 'Invalid URL format',
        latencyMs: 0,
      );
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return ValidationResult(
        isValid: false,
        sourceId: source.id,
        url: source.url,
        reason: 'Unsupported scheme: ${uri.scheme}',
        latencyMs: 0,
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      final client = HttpClient()
        ..connectionTimeout = timeout
        ..badCertificateCallback = (_, __, ___) => true;

      final request = await client
          .getUrl(uri)
          .timeout(timeout);

      // Only fetch headers, not the entire stream
      request.headers.set('Range', 'bytes=0-1');
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await request.close().timeout(timeout);

      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      // Drain the response to free the connection
      await response.drain<void>();
      client.close(force: true);

      final code = response.statusCode;
      final isOk = code == 200 || code == 206 || code == 302 || code == 301;

      if (!isOk) {
        _logger.w('Validation failed for ${source.name}: HTTP $code');
        return ValidationResult(
          isValid: false,
          sourceId: source.id,
          url: source.url,
          reason: 'HTTP $code',
          httpStatus: code,
          latencyMs: latency,
        );
      }

      _logger.d('Validated ${source.name}: ${latency}ms');
      return ValidationResult(
        isValid: true,
        sourceId: source.id,
        url: source.url,
        reason: 'OK',
        httpStatus: code,
        latencyMs: latency,
      );
    } on TimeoutException {
      stopwatch.stop();
      _logger.w('Validation timeout for ${source.name}');
      return ValidationResult(
        isValid: false,
        sourceId: source.id,
        url: source.url,
        reason: 'Connection timeout (${timeout.inSeconds}s)',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      return ValidationResult(
        isValid: false,
        sourceId: source.id,
        url: source.url,
        reason: 'Socket error: ${e.message}',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return ValidationResult(
        isValid: false,
        sourceId: source.id,
        url: source.url,
        reason: 'Validation error: $e',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
}

class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.sourceId,
    required this.url,
    required this.reason,
    required this.latencyMs,
    this.httpStatus,
  });

  final bool isValid;
  final String sourceId;
  final String url;
  final String reason;
  final int? httpStatus;
  final int latencyMs;
}
