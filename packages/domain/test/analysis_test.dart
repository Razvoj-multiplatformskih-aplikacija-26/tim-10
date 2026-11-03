import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final submittedAt = DateTime.utc(2026, 11, 3, 9);
  final now = DateTime.utc(2026, 11, 3, 9, 2);
  final link = VideoLink.parse('https://www.tiktok.com/@kuvarica/video/7301234567890123456').valueOrNull!;

  RecipeContent recipe(String title) =>
      RecipeContent(title: title, ingredients: const [], steps: const [], servings: 2);
  final breakfast = AnalysisResult(link: link, items: [recipe('Palačinke'), recipe('Šakšuka'), recipe('Ovsena kaša')]);

  Entry waiting(EntryStatus status) => Entry(
    id: const EntryId('e-1'),
    owner: const UserId('u-petar'),
    source: FromVideo(link: link),
    status: status,
    createdAt: submittedAt,
    analysisRequests: [submittedAt],
  );

  List<Entry> entriesFor(Entry queued) =>
      entriesFromAnalysis(queued, breakfast, now: now, newId: (i) => EntryId('e-1-$i')).valueOrNull!;

  group('entriesFromAnalysis', () {
    test('a video with three recipes gives three entries, one per item', () {
      final entries = entriesFor(waiting(Queued(at: submittedAt)));

      expect(entries.map((e) => e.content), breakfast.items);
      expect(entries.map((e) => e.source), [
        FromVideo(link: link, itemIndex: 0, itemCount: 3),
        FromVideo(link: link, itemIndex: 1, itemCount: 3),
        FromVideo(link: link, itemIndex: 2, itemCount: 3),
      ]);
    });

    test('the waiting entry keeps its id; the others get new ones', () {
      final entries = entriesFor(waiting(Queued(at: submittedAt)));

      expect(entries.map((e) => e.id), const [EntryId('e-1'), EntryId('e-1-1'), EntryId('e-1-2')]);
      expect(entries.map((e) => e.owner).toSet(), {const UserId('u-petar')});
    });

    test('every item waits for the user\'s review', () {
      final entries = entriesFor(waiting(Analyzing(startedAt: submittedAt)));

      expect(entries.map((e) => e.status).toSet(), {AwaitingReview(analyzedAt: now)});
    });

    test('R2 · one video costs one analysis, not one per item', () {
      final entries = entriesFor(waiting(Queued(at: submittedAt)));

      expect(entries.map((e) => e.analysisRequests), [
        [submittedAt],
        <DateTime>[],
        <DateTime>[],
      ]);
      expect(remainingAnalyses(entries, now: now), dailyAnalysisLimit - 1);
    });

    test('an entry that is not waiting for the analysis cannot take a result', () {
      final saved = waiting(Saved(at: submittedAt));

      expect(
        entriesFromAnalysis(saved, breakfast, now: now, newId: (i) => EntryId('x-$i')).errorOrNull,
        isA<InvalidTransition>(),
      );
    });
  });

  group('entriesFromAnalysis works for any number and kind of items', () {
    RestaurantContent restaurant(String name) => RestaurantContent(
      name: name,
      location: const Location(address: 'Soho', city: 'London'),
      cuisine: 'japanska',
      recommendedDishes: const ['ramen'],
    );

    List<Entry> entriesFrom(List<EntryContent> items) => entriesFromAnalysis(
      waiting(Queued(at: submittedAt)),
      AnalysisResult(link: link, items: items),
      now: now,
      newId: (i) => EntryId('e-1-$i'),
    ).valueOrNull!;

    test('a video with one recipe gives one entry', () {
      final entries = entriesFrom([recipe('Palačinke')]);

      expect(entries, hasLength(1));
      expect(entries.single.source, FromVideo(link: link, itemIndex: 0, itemCount: 1));
    });

    test('"top 10 restaurants in London" gives ten restaurant entries', () {
      final entries = entriesFrom([for (var i = 1; i <= 10; i++) restaurant('Restoran $i')]);

      expect(entries, hasLength(10));
      expect(entries.map((e) => e.content), everyElement(isA<RestaurantContent>()));
      expect(entries.map((e) => (e.source as FromVideo).itemIndex), [for (var i = 0; i < 10; i++) i]);
      expect(entries.map((e) => (e.source as FromVideo).itemCount).toSet(), {10});
      expect(remainingAnalyses(entries, now: now), dailyAnalysisLimit - 1);
    });

    test('a mixed video keeps the kind of each item', () {
      final entries = entriesFrom([restaurant('Kinoko'), recipe('Ramen kao u Kinoku')]);

      expect(entries[0].content, isA<RestaurantContent>());
      expect(entries[1].content, isA<RecipeContent>());
    });
  });
}
