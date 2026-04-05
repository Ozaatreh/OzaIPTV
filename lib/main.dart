import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/environment.dart';

void main() async {
  final container = await bootstrap(
    environment: Environment.development,
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const OzaIPTVApp(),
    ),
  );
}
