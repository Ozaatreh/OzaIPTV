import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import 'environment.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
  ),
);

Future<ProviderContainer> bootstrap({
  Environment environment = Environment.development,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment
  EnvironmentConfig.initialize(environment);

  if (EnvironmentConfig.verboseLogging) {
    logger.i('Bootstrapping OzaIPTV in ${environment.name} mode');
  }

  // System UI configuration for immersive dark experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Orientation support
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Hive for local persistence
  await Hive.initFlutter();

  // Open core Hive boxes
  await Future.wait([
    Hive.openBox<String>('favorites'),
    Hive.openBox<String>('history'),
    Hive.openBox<String>('settings'),
    Hive.openBox<String>('cache'),
    Hive.openBox<String>('recent_searches'),
    Hive.openBox<String>('stream_health'),
  ]);

  if (EnvironmentConfig.verboseLogging) {
    logger.i('Hive boxes initialized');
  }

  // Create the Riverpod container
  final container = ProviderContainer();

  if (EnvironmentConfig.verboseLogging) {
    logger.i('Bootstrap complete');
  }

  return container;
}
