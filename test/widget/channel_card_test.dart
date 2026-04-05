import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozaiptv/design_system/components/channel_card.dart';

void main() {
  group('ChannelCard', () {
    Widget buildCard({
      String name = 'Test Channel',
      bool isLive = false,
      bool isFavorite = false,
      String? currentProgram,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 250,
            child: ChannelCard(
              name: name,
              isLive: isLive,
              isFavorite: isFavorite,
              currentProgram: currentProgram,
              onTap: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('displays channel name', (tester) async {
      await tester.pumpWidget(buildCard(name: 'BBC News'));
      expect(find.text('BBC News'), findsOneWidget);
    });

    testWidgets('shows LIVE badge when isLive is true', (tester) async {
      await tester.pumpWidget(buildCard(isLive: true));
      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('hides LIVE badge when isLive is false', (tester) async {
      await tester.pumpWidget(buildCard(isLive: false));
      expect(find.text('LIVE'), findsNothing);
    });

    testWidgets('shows favorite icon when isFavorite', (tester) async {
      await tester.pumpWidget(buildCard(isFavorite: true));
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('shows current program text', (tester) async {
      await tester.pumpWidget(
        buildCard(currentProgram: 'Evening News'),
      );
      expect(find.text('Evening News'), findsOneWidget);
    });

    testWidgets('displays first letter when no logo', (tester) async {
      await tester.pumpWidget(buildCard(name: 'Alpha'));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 250,
            child: ChannelCard(
              name: 'Tap Me',
              onTap: () => tapped = true,
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });
  });
}
