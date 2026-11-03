import 'package:backoffice/data/fake_review_queue.dart';
import 'package:backoffice/dependencies.dart';
import 'package:backoffice/widgets/queue_skeleton.dart';
import 'package:backoffice/widgets/queue_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

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

      expect(find.text('Red je prazan'), findsOneWidget);
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
}
