import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/seed.dart';
import 'package:ui/ui.dart';

import 'support.dart';

void main() {
  group('the four states of the library (KT1)', () {
    testWidgets('loading, failure, "Pokušaj ponovo", loading, then the data', (tester) async {
      usePhoneSize(tester);
      final dependencies = fakeDependencies(latency: const Duration(seconds: 1));
      dependencies.fakeEntries!.failingRequests = 1;

      await tester.pumpWidget(appWith(dependencies));
      await tester.pump();
      expect(find.byKey(const Key('library-loading')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Biblioteka se nije učitala'), findsOneWidget);

      await tester.tap(find.text('Pokušaj ponovo'));
      await tester.pump();
      expect(find.byKey(const Key('library-loading')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.byKey(const Key('library-loading')), findsNothing);
      expect(find.text('Biblioteka se nije učitala'), findsNothing);
    });

    testWidgets('empty', (tester) async {
      usePhoneSize(tester);
      final dependencies = fakeDependencies();
      dependencies.fakeEntries!.emptyResponses = 1;

      await tester.pumpWidget(appWith(dependencies));
      await tester.pumpAndSettle();

      expect(find.text('Podeli prvi video sa hranom'), findsOneWidget);
      expect(find.text('Dodaj link'), findsOneWidget);
    });
  });

  group('the debug menu', () {
    Future<void> choose(WidgetTester tester, String item) async {
      await tester.tap(find.byTooltip('Još'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(item));
      await tester.pumpAndSettle();
    }

    testWidgets('"Simuliraj grešku", then "Osveži", shows the failure', (tester) async {
      usePhoneSize(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      await choose(tester, 'Simuliraj grešku');
      await choose(tester, 'Osveži');

      expect(find.text('Biblioteka se nije učitala'), findsOneWidget);
    });

    testWidgets('"Prazan odgovor", then "Osveži", shows the empty library', (tester) async {
      usePhoneSize(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      await choose(tester, 'Prazan odgovor');
      await choose(tester, 'Osveži');

      expect(find.text('Podeli prvi video sa hranom'), findsOneWidget);
    });
  });

  group('the cards', () {
    testWidgets('the seed shows at least ten entries, in every state', (tester) async {
      final entries = demoEntries(testNow);

      expect(entries.where((entry) => entry.owner == demoUser.id).length, greaterThanOrEqualTo(10));
      expect(entries.map((entry) => entry.status.runtimeType).toSet().length, 8);
    });

    testWidgets('a card shows the name and the state of the entry', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(700, 4000);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      expect(find.text('Za pregled'), findsWidgets);
      expect(find.text('Čeka analizu'), findsWidgets);
      expect(find.text('Izdvajamo recept iz videa'), findsOneWidget);
    });
  });

  group('the filters', () {
    Future<void> loaded(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(700, 6000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();
    }

    testWidgets('the segment "Restorani" hides the recipes', (tester) async {
      await loaded(tester);
      expect(find.text('Salata od leblebija'), findsNothing); // only after the video is analysed
      final allCards = find.byType(EntryCard).evaluate().length;

      await tester.tap(find.text('Restorani'));
      await tester.pumpAndSettle();

      expect(find.byType(EntryCard).evaluate().length, lessThan(allCards));
      expect(find.text('Recept'), findsNothing);
    });

    testWidgets('the banner shows only the entries waiting for review, and tapping the chip again shows all', (
      tester,
    ) async {
      await loaded(tester);
      final allCards = find.byType(EntryCard).evaluate().length;

      await tester.tap(find.text('Pregledaj'));
      await tester.pumpAndSettle();
      expect(find.byType(EntryCard).evaluate().length, lessThan(allCards));
      expect(find.text('Sačuvano'), findsOneWidget); // only the chip; no card has this state now

      await tester.tap(find.text('Za pregled').first);
      await tester.pumpAndSettle();
      expect(find.byType(EntryCard).evaluate().length, allCards);
    });
  });
}
