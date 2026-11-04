import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/seed.dart';
import 'package:mobile/dependencies.dart';
import 'package:ui/ui.dart';

import 'support.dart';

void main() {
  Future<void> openForm(WidgetTester tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies(), location: '/entries/new'));
    await tester.pumpAndSettle();
  }

  group('R1 · the link while typing', () {
    testWidgets('an empty field shows no error, and the button is off', (tester) async {
      await openForm(tester);

      expect(find.textContaining('Ovo ne liči'), findsNothing);
      final button = tester.widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'Analiziraj video'));
      expect(button.onPressed, isNull);
    });

    testWidgets('text that is not a link shows the message from ui', (tester) async {
      await openForm(tester);

      await tester.enterText(find.byType(LinkField), 'palačinke sa bananom');
      await tester.pumpAndSettle();

      final message = domainErrorText(const InvalidLink(), now: testNow);
      expect(find.text(message), findsOneWidget);
    });

    testWidgets('another platform says which ones we support', (tester) async {
      await openForm(tester);

      await tester.enterText(find.byType(LinkField), 'https://youtube.com/shorts/aB3xYz');
      await tester.pumpAndSettle();

      expect(find.textContaining('Za sada podržavamo samo Instagram i TikTok'), findsOneWidget);
    });

    testWidgets('a good link is recognized and turns the button on', (tester) async {
      await openForm(tester);

      await tester.enterText(find.byType(LinkField), knownVideoUrl);
      await tester.pumpAndSettle();

      expect(find.text('Video je prepoznat'), findsOneWidget);
      final button = tester.widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'Analiziraj video'));
      expect(button.onPressed, isNotNull);
    });
  });

  group('R2 · the daily counter', () {
    testWidgets('shows how many analyses are left', (tester) async {
      await openForm(tester);

      expect(find.textContaining('od $dailyAnalysisLimit'), findsOneWidget);
    });
  });

  group('sending', () {
    testWidgets('closes the form, says so and shows the new entry first', (tester) async {
      await openForm(tester);

      await tester.enterText(find.byType(LinkField), knownVideoUrl);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analiziraj video'));
      await tester.pumpAndSettle();

      expect(find.text('Analiziramo video. Javićemo kad bude gotovo.'), findsOneWidget);
      expect(find.text('Dodaj video'), findsNothing);
    });

    testWidgets('a video someone already analysed is there at once (R4)', (tester) async {
      await openForm(tester);

      await tester.enterText(find.byType(LinkField), anasVideoUrl);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analiziraj video'));
      await tester.pumpAndSettle();

      expect(find.text('Ovaj video je već analiziran. Rezultat je odmah tu.'), findsOneWidget);
    });

    testWidgets('a lost connection keeps the link and offers "Pokušaj ponovo"', (tester) async {
      usePhoneSize(tester);
      final dependencies = fakeDependencies();
      await tester.pumpWidget(appWith(dependencies, location: '/entries/new'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(LinkField), knownVideoUrl);
      await tester.pumpAndSettle();
      dependencies.fakeEntries!.failingRequests = 1;

      await tester.tap(find.text('Analiziraj video'));
      await tester.pumpAndSettle();

      expect(find.text('Slanje nije uspelo. Proveri internet vezu.'), findsOneWidget);
      expect(find.text('Video je prepoznat'), findsOneWidget);
    });

    Future<AppDependencies> failToSend(WidgetTester tester) async {
      usePhoneSize(tester);
      final dependencies = fakeDependencies();
      await tester.pumpWidget(appWith(dependencies));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dodaj'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(LinkField), knownVideoUrl);
      await tester.pumpAndSettle();
      dependencies.fakeEntries!.failingRequests = 1;
      await tester.tap(find.text('Analiziraj video'));
      await tester.pumpAndSettle();
      return dependencies;
    }

    testWidgets('closing the form takes its "Pokušaj ponovo" with it', (tester) async {
      await failToSend(tester);

      await tester.tap(find.byTooltip('Zatvori'));
      await tester.pumpAndSettle();

      expect(find.text('Dodaj video'), findsNothing);
      expect(find.text('Pokušaj ponovo'), findsNothing);
    });

    testWidgets('the system back button takes "Pokušaj ponovo" with it too', (tester) async {
      await failToSend(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Dodaj video'), findsNothing);
      expect(find.text('Pokušaj ponovo'), findsNothing);
    });

    testWidgets('"Pokušaj ponovo" sends again, and the success message outlives the form', (tester) async {
      await failToSend(tester);

      await tester.tap(find.text('Pokušaj ponovo'));
      await tester.pumpAndSettle();

      expect(find.text('Dodaj video'), findsNothing);
      expect(find.text('Analiziramo video. Javićemo kad bude gotovo.'), findsOneWidget);
    });

    testWidgets('a new video is not hidden by the filter picked before adding it', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(700, 6000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();
      final allCards = find.byType(EntryCard).evaluate().length;

      await tester.tap(find.text('Restorani'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dodaj'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(LinkField), knownVideoUrl);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analiziraj video'));
      await tester.pumpAndSettle();

      expect(find.byType(EntryCard).evaluate().length, allCards + 1);
    });

    testWidgets('"Dodaj" in the tab bar opens the form', (tester) async {
      usePhoneSize(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dodaj'));
      await tester.pumpAndSettle();

      expect(find.text('Dodaj video'), findsOneWidget);
    });
  });
}
