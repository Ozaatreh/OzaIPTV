import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozaiptv/design_system/components/loading_states.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('displays title and subtitle', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.search,
            title: 'Nothing here',
            subtitle: 'Try searching for something',
          ),
        ),
      ));

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Try searching for something'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.add,
            title: 'Empty',
            actionLabel: 'Add Item',
            onAction: () {},
          ),
        ),
      ));

      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('hides action button when not provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.add,
            title: 'Empty',
          ),
        ),
      ));

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('ErrorStateWidget', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ErrorStateWidget(
            message: 'Network timeout',
          ),
        ),
      ));

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Network timeout'), findsOneWidget);
    });

    testWidgets('shows retry button when handler provided', (tester) async {
      var retried = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorStateWidget(
            message: 'Error',
            onRetry: () => retried = true,
          ),
        ),
      ));

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });
}
