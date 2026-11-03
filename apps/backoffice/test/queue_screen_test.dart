import 'package:backoffice/widgets/queue_skeleton.dart';
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
}
