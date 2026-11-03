import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/fake_entry_repository.dart';
import 'package:mobile/data/fake_video_analyzer.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  const petar = User(id: UserId('u-petar'), role: Role.user);
  const ana = UserId('u-ana');
  final now = DateTime.utc(2026, 11, 4, 12);
  final clock = FixedClock(now);

  VideoLink linkOf(String text) => VideoLink.parse(text).valueOrNull!;
  final breakfast = linkOf('https://www.tiktok.com/@doruckuj.brzo/video/7301234567890123456');
  final unknown = linkOf('https://www.instagram.com/reel/NepoznatVideo/');

  RecipeContent recipe(String title) =>
      RecipeContent(title: title, ingredients: const [], steps: const [], servings: 2);
  final breakfastItems = [recipe('Palačinke'), recipe('Šakšuka'), recipe('Ovsena kaša')];

  FakeEntryRepository repositoryWith(List<Entry> seed) => FakeEntryRepository(
    seed: seed,
    clock: clock,
    analyzer: FakeVideoAnalyzer({breakfast: breakfastItems}, latency: Duration.zero),
    latency: Duration.zero,
  );

  /// Lets the analysis that runs in the background finish.
  Future<void> analysisFinished() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('FakeEntryRepository.submitLink', () {
    test('a new link waits in the queue, then becomes one entry per item, for review', () async {
      final repository = repositoryWith([]);

      final sent = await repository.submitLink(breakfast, owner: petar.id);
      expect(sent.valueOrNull?.single.status, Queued(at: now));

      await analysisFinished();
      final mine = await repository.entriesOf(petar.id);

      expect(mine.map((e) => e.content), unorderedEquals(breakfastItems));
      expect(mine.map((e) => e.status).toSet(), {AwaitingReview(analyzedAt: now)});
      expect(remainingAnalyses(mine, now: now), dailyAnalysisLimit - 1);
    });

    test('a video the analyzer does not know ends as "not food"', () async {
      final repository = repositoryWith([]);

      await repository.submitLink(unknown, owner: petar.id);
      await analysisFinished();

      expect(
        (await repository.entriesOf(petar.id)).single.status,
        AnalysisFailed(reason: AnalysisFailure.notFood, at: now),
      );
    });

    test('R4 · a video Ana already analysed comes to Petar at once, and still counts as his link', () async {
      final anas = [
        for (var i = 0; i < breakfastItems.length; i++)
          Entry(
            id: EntryId('ana-$i'),
            owner: ana,
            source: FromVideo(link: breakfast, itemIndex: i, itemCount: breakfastItems.length),
            status: Saved(at: now),
            createdAt: now,
            content: breakfastItems[i],
          ),
      ];
      final repository = repositoryWith(anas);

      final sent = (await repository.submitLink(breakfast, owner: petar.id)).valueOrNull!;

      expect(sent, hasLength(3));
      expect(sent.map((e) => e.status).toSet(), {AwaitingReview(analyzedAt: now)});
      expect(sent.map((e) => e.owner).toSet(), {petar.id});
      expect(remainingAnalyses(sent, now: now), dailyAnalysisLimit - 1);
    });

    test('R2 · the 21st link of the day is refused', () async {
      final twenty = [
        for (var i = 0; i < 20; i++)
          Entry(
            id: EntryId('p-$i'),
            owner: petar.id,
            source: FromVideo(link: unknown),
            status: Saved(at: now),
            createdAt: now,
            analysisRequests: [now.subtract(const Duration(hours: 1))],
          ),
      ];

      final result = await repositoryWith(twenty).submitLink(breakfast, owner: petar.id);

      expect(result.errorOrNull, isA<DailyLimitReached>());
    });

    test('"Pokušaj ponovo" runs the analysis again', () async {
      final failed = Entry(
        id: const EntryId('p-failed'),
        owner: petar.id,
        source: FromVideo(link: breakfast),
        status: AnalysisFailed(reason: AnalysisFailure.timeout, at: now),
        createdAt: now,
        analysisRequests: [now],
      );
      final repository = repositoryWith([failed]);

      final retried = await RetryAnalysis(entries: repository, clock: clock)(failed.id, by: petar);
      expect(retried.valueOrNull?.status, Queued(at: now));

      await analysisFinished();
      final mine = await repository.entriesOf(petar.id);

      expect(mine, hasLength(3));
      expect(mine.map((e) => e.status).toSet(), {AwaitingReview(analyzedAt: now)});
    });
  });
}
