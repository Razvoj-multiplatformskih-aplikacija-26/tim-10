import 'package:backoffice/data/fake_review_queue.dart';
import 'package:backoffice/dependencies.dart';
import 'package:backoffice/screens/queue_screen.dart';
import 'package:backoffice/widgets/queue_list.dart';
import 'package:backoffice/widgets/queue_skeleton.dart';
import 'package:backoffice/widgets/queue_table.dart';
import 'package:backoffice/widgets/review_detail_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support.dart';

void main() {
  group('the four states of the queue (KT1)', () {
    testWidgets('loading, failure, "Pokušaj ponovo", then the data', (tester) async {
      useWideWindow(tester);
      final dependencies = fakeDependencies(latency: const Duration(seconds: 1));
      dependencies.fakeQueue!.failingRequests = 1;

      await tester.pumpWidget(appWith(dependencies));
      await tester.pump();
      expect(find.byType(QueueSkeleton), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Predlozi nisu učitani'), findsOneWidget);

      await tester.tap(find.text('Pokušaj ponovo'));
      await tester.pump();
      expect(find.byType(QueueSkeleton), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Paprika'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      useWideWindow(tester);
      final dependencies = fakeDependencies();
      dependencies.fakeQueue!.emptyResponses = 1;

      await tester.pumpWidget(appWith(dependencies));
      await tester.pumpAndSettle();

      expect(find.text('Red je prazan. Svaka čast!'), findsOneWidget);
    });
  });

  group('the detail panel', () {
    testWidgets('a click on a row opens its detail next to the table', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();
      expect(find.text('Kuhinja: domaća'), findsNothing);

      await tester.tap(find.text('Paprika'));
      await tester.pumpAndSettle();

      expect(find.text('Kuhinja: domaća'), findsOneWidget);
      expect(find.text('Cara Dušana 14, Beograd'), findsOneWidget);
    });

    testWidgets('never shows the personal layer (R7)', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Paprika'));
      await tester.pumpAndSettle();

      expect(find.textContaining('rođendan'), findsNothing);
      expect(find.text('Lični podaci korisnika nisu vidljivi uredniku'), findsOneWidget);
    });

    testWidgets('puts a possible duplicate next to the proposal (R5)', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Paprika'));
      await tester.pumpAndSettle();

      expect(find.text('Mogući duplikati u katalogu (1)'), findsOneWidget);
      expect(find.text('Bistro Paprika'), findsOneWidget);
    });

    testWidgets('the close button closes the panel', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paprika'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Zatvori (Esc)'));
      await tester.pumpAndSettle();

      expect(find.text('Kuhinja: domaća'), findsNothing);
    });
  });

  group('the decisions', () {
    Future<void> openFirst(WidgetTester tester, {void Function(FakeReviewQueue)? setUp}) async {
      useWideWindow(tester);
      final dependencies = fakeDependencies();
      setUp?.call(dependencies.fakeQueue!);
      await tester.pumpWidget(appWith(dependencies));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paprika'));
      await tester.pumpAndSettle();
    }

    testWidgets('"Objavi" takes the proposal out of the queue and says so', (tester) async {
      await openFirst(tester);

      await tester.tap(find.text('Objavi (O)'));
      await tester.pumpAndSettle();

      expect(find.text('Paprika'), findsNothing);
      expect(find.text('Objavljeno u katalogu.'), findsOneWidget);
    });

    testWidgets('"Odbij" asks for a reason, and an empty reason is refused with the text from ui', (tester) async {
      await openFirst(tester);

      await tester.tap(find.text('Odbij (X)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Odbij'));
      await tester.pumpAndSettle();

      expect(find.text('Upiši razlog odbijanja.'), findsOneWidget);
      expect(find.text('Paprika'), findsWidgets);
    });

    testWidgets('"Odbij" with a reason takes the proposal out of the queue', (tester) async {
      await openFirst(tester);

      await tester.tap(find.text('Odbij (X)'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('reject-reason')), 'Video nije o hrani.');
      await tester.tap(find.text('Odbij'));
      await tester.pumpAndSettle();

      expect(find.text('Paprika'), findsNothing);
      expect(find.text('Predlog je odbijen.'), findsOneWidget);
    });

    testWidgets('"Odustani" changes nothing', (tester) async {
      await openFirst(tester);

      await tester.tap(find.text('Odbij (X)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Odustani'));
      await tester.pumpAndSettle();

      expect(find.text('Paprika'), findsWidgets);
      expect(find.text('Predlog je odbijen.'), findsNothing);
    });

    testWidgets('a lost connection keeps the proposal and offers "Pokušaj ponovo"', (tester) async {
      await openFirst(tester);
      final fake = RepositoryProvider.of<AppDependencies>(tester.element(find.byType(QueueTable))).fakeQueue!;
      fake.failingRequests = 1;

      await tester.tap(find.text('Objavi (O)'));
      await tester.pumpAndSettle();

      expect(find.text('Nije sačuvano.'), findsOneWidget);
      expect(find.text('Paprika'), findsWidgets);

      await tester.tap(find.widgetWithText(SnackBarAction, 'Pokušaj ponovo'));
      await tester.pumpAndSettle();

      expect(find.text('Objavljeno u katalogu.'), findsOneWidget);
    });
  });

  group('working with the keyboard only', () {
    Future<void> loaded(WidgetTester tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();
    }

    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    testWidgets('the arrows and Enter open a proposal, and Esc closes it', (tester) async {
      await loaded(tester);

      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.enter);
      expect(find.text('Sastojci'), findsOneWidget); // p-2 is a recipe
      expect(find.text('2. Dodaj paradajz i jaja.'), findsOneWidget);

      await press(tester, LogicalKeyboardKey.escape);
      expect(find.text('Sastojci'), findsNothing);
    });

    testWidgets('the open panel follows the cursor', (tester) async {
      await loaded(tester);

      await press(tester, LogicalKeyboardKey.enter);
      expect(find.text('Kuhinja: domaća'), findsOneWidget);

      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(find.text('Kuhinja: domaća'), findsNothing);
      expect(find.text('Sastojci'), findsOneWidget);
    });

    testWidgets('O publishes the proposal under the cursor', (tester) async {
      await loaded(tester);

      await press(tester, LogicalKeyboardKey.keyO);

      expect(find.text('Paprika'), findsNothing);
      expect(find.text('Objavljeno u katalogu.'), findsOneWidget);
    });

    testWidgets('X asks for the reason, and the keyboard still works after the dialog', (tester) async {
      await loaded(tester);

      await press(tester, LogicalKeyboardKey.keyX);
      await tester.enterText(find.byKey(const Key('reject-reason')), 'Video nije o hrani.');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Predlog je odbijen.'), findsOneWidget);
      expect(find.text('Paprika'), findsNothing);

      await press(tester, LogicalKeyboardKey.enter);
      expect(find.text('Sastojci'), findsOneWidget); // the next proposal, p-2
    });

    testWidgets('the cursor scrolls the table to rows out of view', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();
      expect(find.text('Kokos kari sa piletinom'), findsNothing);

      for (var i = 0; i < 11; i++) {
        await press(tester, LogicalKeyboardKey.arrowDown);
      }

      expect(find.text('Kokos kari sa piletinom'), findsOneWidget);
    });
  });

  group('a narrow window', () {
    void useNarrowWindow(WidgetTester tester) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 800);
      addTearDown(tester.view.reset);
    }

    testWidgets('shows a list instead of the table', (tester) async {
      useNarrowWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      expect(find.byType(QueueList), findsOneWidget);
      expect(find.byType(QueueTable), findsNothing);
    });

    testWidgets('narrowing and widening the window keeps the open proposal', (tester) async {
      final titleInPanel = find.descendant(of: find.byType(ReviewDetailPanel), matching: find.text('Šakšuka'));

      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(titleInPanel, findsOneWidget);

      useNarrowWindow(tester);
      await tester.pumpAndSettle();
      expect(find.byType(QueueList), findsOneWidget);
      expect(titleInPanel, findsOneWidget);

      useWideWindow(tester);
      await tester.pumpAndSettle();
      expect(find.byType(QueueTable), findsOneWidget);
      expect(titleInPanel, findsOneWidget);
    });

    testWidgets('the keyboard works the same in the list', (tester) async {
      useNarrowWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
      await tester.pumpAndSettle();

      expect(find.text('Objavljeno u katalogu.'), findsOneWidget);
    });

    testWidgets('the list opens at the row under the cursor', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 300);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();
      for (var i = 0; i < 11; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(600, 300);
      await tester.pumpAndSettle();

      expect(find.text('Kokos kari sa piletinom'), findsOneWidget);
    });
  });

  group('the address', () {
    String addressOf(WidgetTester tester) =>
        GoRouter.of(tester.element(find.byType(QueueScreen))).routeInformationProvider.value.uri.toString();

    testWidgets('a link with a selection opens that proposal', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies(), location: '/queue?entry=p-2'));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(ReviewDetailPanel), matching: find.text('Šakšuka')), findsOneWidget);
    });

    testWidgets('opening and closing a proposal changes the address', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();
      expect(addressOf(tester), '/queue');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(addressOf(tester), '/queue?entry=p-1');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(addressOf(tester), '/queue?entry=p-2');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(addressOf(tester), '/queue');
    });

    testWidgets('a new address opens that proposal', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      GoRouter.of(tester.element(find.byType(QueueScreen))).go('/queue?entry=p-2');
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(ReviewDetailPanel), matching: find.text('Šakšuka')), findsOneWidget);
    });

    testWidgets('an old link opens nothing and cleans the address', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies(), location: '/queue?entry=p-99'));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewDetailPanel), findsNothing);
      expect(addressOf(tester), '/queue');
    });

    testWidgets('the root address goes to the queue', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies(), location: '/'));
      await tester.pumpAndSettle();

      expect(find.byType(QueueTable), findsOneWidget);
    });
  });

  group('the menu', () {
    Future<void> choose(WidgetTester tester, String item) async {
      await tester.tap(find.byTooltip('Još'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(item));
      await tester.pumpAndSettle();
    }

    testWidgets('"Simuliraj grešku", then "Osveži", shows the failure', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      await choose(tester, 'Simuliraj grešku');
      await choose(tester, 'Osveži');

      expect(find.text('Predlozi nisu učitani'), findsOneWidget);
    });

    testWidgets('"Prazan odgovor", then "Osveži", shows the empty queue', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      await choose(tester, 'Prazan odgovor');
      await choose(tester, 'Osveži');

      expect(find.text('Red je prazan. Svaka čast!'), findsOneWidget);
    });

    testWidgets('"Prečice" lists the keys', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      await choose(tester, 'Prečice (?)');

      expect(find.text('objavi'), findsOneWidget);
      expect(find.text('odbij, uz razlog'), findsOneWidget);
    });

    testWidgets('the keyboard still works after the menu', (tester) async {
      useWideWindow(tester);
      await tester.pumpWidget(appWith(fakeDependencies()));
      await tester.pumpAndSettle();

      await choose(tester, 'Osveži');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
      await tester.pumpAndSettle();

      expect(find.text('Objavljeno u katalogu.'), findsOneWidget);
    });
  });
}
