import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/seed.dart';

import 'support.dart';

void main() {
  final entries = demoEntries(testNow).where((entry) => entry.owner == demoUser.id).toList();
  Entry withStatus<T extends EntryStatus>() => entries.firstWhere((entry) => entry.status is T);

  void useTallPhone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(700, 1600);
    addTearDown(tester.view.reset);
  }

  Future<void> open(WidgetTester tester, Entry entry) async {
    useTallPhone(tester);
    await tester.pumpWidget(appWith(fakeDependencies(), location: '/entries/${entry.id.value}'));
    await tester.pumpAndSettle();
  }

  group('the detail on its own screen', () {
    testWidgets('a card opens its entry, with the id in the address', (tester) async {
      useTallPhone(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();
      final saved = withStatus<Saved>();

      await tester.tap(find.text(_titleOf(saved)).first);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Nazad'), findsOneWidget);
    });

    testWidgets('a recipe shows ingredients and steps', (tester) async {
      final recipe = entries.firstWhere((entry) => entry.content is RecipeContent && entry.status is Saved);
      await open(tester, recipe);

      expect(find.text('Sastojci'), findsOneWidget);
      expect(find.text('Koraci'), findsOneWidget);
    });

    testWidgets('a restaurant shows the address and the dishes', (tester) async {
      final restaurant = entries.firstWhere((entry) => entry.content is RestaurantContent);
      await open(tester, restaurant);

      expect(find.text('Adresa'), findsOneWidget);
      expect(find.text('Preporučena jela'), findsOneWidget);
    });

    testWidgets('the tab "Moje" is marked private', (tester) async {
      await open(tester, withStatus<Saved>());

      await tester.tap(find.text('Moje'));
      await tester.pumpAndSettle();

      expect(find.text('Privatno: vidiš samo ti, nikad urednik.'), findsOneWidget);
    });

    testWidgets('an unknown id says the entry was not found', (tester) async {
      useTallPhone(tester);
      await tester.pumpWidget(appWith(fakeDependencies(), location: '/entries/nema-ga'));
      await tester.pumpAndSettle();

      expect(find.text('Unos nije pronađen'), findsOneWidget);
    });
  });

  group('the actions', () {
    testWidgets('"Sačuvaj" moves the entry to the saved state', (tester) async {
      await open(tester, withStatus<AwaitingReview>());

      await tester.tap(find.text('Sačuvaj'));
      await tester.pumpAndSettle();

      expect(find.text('Sačuvano u biblioteci.'), findsOneWidget);
      expect(find.text('Predloži za katalog'), findsOneWidget);
    });

    testWidgets('"Predloži za katalog" asks first and says what stays private', (tester) async {
      await open(tester, withStatus<Saved>());

      await tester.tap(find.text('Predloži za katalog'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ostaju privatne'), findsOneWidget);

      await tester.tap(find.text('Predloži'));
      await tester.pumpAndSettle();
      expect(find.text('Predlog je poslat uredniku.'), findsOneWidget);
      expect(find.text('Čeka urednika'), findsOneWidget);
    });

    testWidgets('"Obriši" asks first, and "Odustani" keeps the entry', (tester) async {
      await open(tester, withStatus<Saved>());

      await tester.tap(find.byTooltip('Još'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Obriši'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Odustani'));
      await tester.pumpAndSettle();

      expect(find.text('Unos je obrisan.'), findsNothing);
      expect(find.byTooltip('Nazad'), findsOneWidget);
    });

    testWidgets('a confirmed "Obriši" goes back to the library and says so', (tester) async {
      useTallPhone(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();
      final saved = withStatus<Saved>();
      await tester.tap(find.text(_titleOf(saved)).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Još'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Obriši'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Obriši'));
      await tester.pumpAndSettle();

      expect(find.text('Unos je obrisan.'), findsOneWidget);
      expect(find.byTooltip('Nazad'), findsNothing);
      expect(find.text(_titleOf(saved)), findsNothing);
    });

    testWidgets('deleting the last entry goes back to the empty library and says so', (tester) async {
      useTallPhone(tester);
      final dependencies = fakeDependencies();
      await tester.pumpWidget(appWith(dependencies));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_titleOf(withStatus<Saved>())).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Još'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Obriši'));
      await tester.pumpAndSettle();
      dependencies.fakeEntries!.emptyResponses = 1; // the reload after the delete finds nothing left
      await tester.tap(find.text('Obriši'));
      await tester.pumpAndSettle();

      expect(find.text('Unos je obrisan.'), findsOneWidget);
      expect(find.byTooltip('Nazad'), findsNothing);
      expect(find.text('Podeli prvi video sa hranom'), findsOneWidget);
      expect(find.text('Dodaj link'), findsOneWidget);
    });

    testWidgets('an entry being analysed has no actions (R3)', (tester) async {
      await open(tester, withStatus<Analyzing>());

      expect(find.byTooltip('Još'), findsNothing);
      expect(find.text('Sačuvaj'), findsNothing);
    });

    testWidgets('a failed analysis offers "Pokušaj ponovo"', (tester) async {
      await open(tester, withStatus<AnalysisFailed>());

      expect(find.text('Pokušaj ponovo'), findsOneWidget);
    });

    testWidgets('a rejected entry shows the reason and can be proposed again', (tester) async {
      await open(tester, withStatus<Rejected>());

      expect(find.textContaining('Urednik je odbio predlog'), findsOneWidget);
      expect(find.text('Predloži ponovo'), findsOneWidget);
    });
  });
}

String _titleOf(Entry entry) => switch (entry.content) {
  RecipeContent(:final title) => title,
  RestaurantContent(:final name) => name,
  null => throw StateError('no content'),
};
