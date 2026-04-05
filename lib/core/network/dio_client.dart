import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../app/environment.dart';

final dioProvider = Provider<Dio>((ref) {
  return DioClient.create();
});

class DioClient {
  DioClient._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvironmentConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Version': EnvironmentConfig.appVersion,
        },
      ),
    );

    if (EnvironmentConfig.verboseLogging) {
      dio.interceptors.add(_LoggingInterceptor());
    }

    dio.interceptors.add(_ErrorInterceptor());

    return dio;
  }
}

class _LoggingInterceptor extends Interceptor {
  final _logger = Logger(printer: SimplePrinter());

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _logger.d('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('✗ ${err.type}: ${err.message}');
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Centralized error transformation
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: 'Connection timed out. Please check your network.',
            type: err.type,
          ),
        );
      case DioExceptionType.connectionError:
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: 'No internet connection.',
            type: err.type,
          ),
        );
      default:
        handler.next(err);
    }
  }
}
