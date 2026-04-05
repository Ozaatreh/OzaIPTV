import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/stream_source.dart';

final streamValidatorProvider = Provider<StreamValidator>(
  (ref) => StreamValidator(),
);

class StreamValidator {
  final _logger = Logger(printer: SimplePrinter());

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
      final host = uri.host;
      if (host.isEmpty) {
        return ValidationResult(
          isValid: false,
          sourceId: source.id,
          url: source.url,
          reason: 'Missing host',
          latencyMs: 0,
        );
      }

      // 1) DNS check only
      final lookup = await InternetAddress.lookup(host).timeout(timeout);
      if (lookup.isEmpty || lookup.first.rawAddress.isEmpty) {
        stopwatch.stop();
        return ValidationResult(
          isValid: false,
          sourceId: source.id,
          url: source.url,
          reason: 'DNS lookup failed',
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      }

      // 2) Soft probe
      final client = HttpClient()
        ..connectionTimeout = timeout
        ..badCertificateCallback = (_, __, ___) => true;

      try {
        final request = await client.getUrl(uri).timeout(timeout);
        request.headers.set(HttpHeaders.userAgentHeader, 'OzaIPTV/1.0');
        request.headers.set(HttpHeaders.acceptHeader, '*/*');
        request.headers.set(HttpHeaders.connectionHeader, 'keep-alive');
        request.followRedirects = true;
        request.maxRedirects = 5;

        final response = await request.close().timeout(timeout);
        final code = response.statusCode;

        await response.drain<void>();
        client.close(force: true);
        stopwatch.stop();

        // For streaming endpoints, strict probe checks often create false negatives.
        // If DNS works and we got any real HTTP response, let the player try it.
        final softValid = code >= 200 && code < 500;

        if (softValid) {
          _logger.d('Soft-validated ${source.name}: HTTP $code');
          return ValidationResult(
            isValid: true,
            sourceId: source.id,
            url: source.url,
            reason: 'HTTP $code (soft valid)',
            httpStatus: code,
            latencyMs: stopwatch.elapsedMilliseconds,
          );
        }

        return ValidationResult(
          isValid: false,
          sourceId: source.id,
          url: source.url,
          reason: 'HTTP $code',
          httpStatus: code,
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      } catch (_) {
        client.close(force: true);
        stopwatch.stop();

        // DNS passed, so do not hard-fail here.
        // Let the native player attempt playback.
        return ValidationResult(
          isValid: true,
          sourceId: source.id,
          url: source.url,
          reason: 'Probe skipped after DNS success',
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      }
    } on TimeoutException {
      stopwatch.stop();
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
