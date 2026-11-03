import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
