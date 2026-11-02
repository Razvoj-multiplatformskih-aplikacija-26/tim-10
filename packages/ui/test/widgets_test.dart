import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(
    body: ListView(padding: const EdgeInsets.all(AppSpace.screen), children: [child]),
  ),
);

void main() {
  testWidgets('a badge shows the Serbian text for each of the eight states', (tester) async {
    await tester.pumpWidget(_wrap(Wrap(children: [for (final status in BadgeStatus.values) StatusBadge(status)])));

    for (final text in [
      'Čeka analizu',
      'Analizira se',
      'Za pregled',
      'Sačuvano',
      'Nije uspelo',
      'Čeka urednika',
      'U katalogu',
      'Odbijeno',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('a badge takes its colors from the StatusColors theme extension', (tester) async {
    const changed = BadgeColors(background: AppColors.cobaltSoft, foreground: AppColors.cobalt);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light().copyWith(extensions: [StatusColors.light.copyWith(saved: changed)]),
        home: const Scaffold(body: StatusBadge(BadgeStatus.saved)),
      ),
    );

    final box = tester.widget<Container>(
      find.descendant(of: find.byType(StatusBadge), matching: find.byType(Container)),
    );
    expect((box.decoration! as BoxDecoration).color, AppColors.cobaltSoft);
    expect(tester.widget<Text>(find.text('Sačuvano')).style?.color, AppColors.cobalt);
  });

  testWidgets('tapping a segment reports its index', (tester) async {
    int? selected;
    await tester.pumpWidget(
      _wrap(
        SegmentedTabs(labels: const ['Sve', 'Recepti', 'Restorani'], selectedIndex: 0, onSelected: (i) => selected = i),
      ),
    );

    await tester.tap(find.text('Restorani'));

    expect(selected, 2);
  });

  testWidgets('the link field shows the error and clears the text with ×', (tester) async {
    final controller = TextEditingController(text: 'palačinke');
    addTearDown(controller.dispose);
    String? changed;
    await tester.pumpWidget(
      _wrap(
        LinkField(controller: controller, errorText: 'Ovo ne liči na link do videa.', onChanged: (v) => changed = v),
      ),
    );

    expect(find.text('Ovo ne liči na link do videa.'), findsOneWidget);

    await tester.tap(find.byTooltip('Obriši'));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(changed, '');
    expect(find.byTooltip('Obriši'), findsNothing);
  });

  testWidgets('an entry card shows its type, status, title, facts, note and group', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EntryCard(
          kind: EntryCardKind.restaurant,
          status: BadgeStatus.saved,
          title: 'Ramen bar Kinoko',
          thumb: ReelThumb(sourceLabel: 'Instagram'),
          facts: [EntryFact(icon: AppIcons.location, text: 'Dorćol')],
          personalNote: 'Vratio bih se',
          author: '@beograd.jede',
          groupLabel: '1 od 3',
        ),
      ),
    );

    for (final text in [
      'Restoran',
      'Sačuvano',
      'Ramen bar Kinoko',
      'Dorćol',
      'Vratio bih se',
      '@beograd.jede',
      '1 od 3',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('buttons, chips and the tab bar meet contrast and tap target guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: [
              PrimaryButton(label: 'Dodaj link', onPressed: () {}),
              GhostButton(label: 'Pogledaj primer', onPressed: () {}),
              FilterChips(
                items: const [
                  FilterChipItem(label: 'Za pregled', count: 2, highlighted: true),
                  FilterChipItem(label: 'Sačuvano'),
                ],
                onSelected: (_) {},
              ),
              Wrap(children: [for (final status in BadgeStatus.values) StatusBadge(status)]),
            ],
          ),
          bottomNavigationBar: AppTabBar(currentIndex: 0, onSelected: (_) {}, onAdd: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });
}
