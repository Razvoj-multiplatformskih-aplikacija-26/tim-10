import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/in_memory_entry_repository.dart';

void main() {
  final now = DateTime.utc(2026, 11, 4, 12);
  final clock = FixedClock(now);
  const petar = User(id: UserId('u-petar'), role: Role.user);
  const ana = User(id: UserId('u-ana'), role: Role.user);
  final link = VideoLink.parse('https://www.instagram.com/reel/C8xYz12AbC/').valueOrNull!;

  /// [count] saved entries of [owner], each analysed [ago] before now.
  List<Entry> analysed(User owner, int count, {Duration ago = const Duration(hours: 1)}) => [
    for (var i = 0; i < count; i++)
      Entry(
        id: EntryId('${owner.id.value}-$i'),
        owner: owner.id,
        source: FromVideo(link: link),
        status: Saved(at: now),
        createdAt: now.subtract(ago),
        analysisRequests: [now.subtract(ago)],
      ),
  ];

  group('LoadMyEntries', () {
    test('gives the user their own entries and nobody else\'s', () async {
      final repository = InMemoryEntryRepository([...analysed(petar, 2), ...analysed(ana, 3)]);

      final mine = await LoadMyEntries(entries: repository)(petar);

      expect(mine, hasLength(2));
      expect(mine.map((e) => e.owner).toSet(), {petar.id});
    });

    test('lets a lost connection through to the caller', () async {
      final repository = InMemoryEntryRepository()..failNextCall = true;

      await expectLater(LoadMyEntries(entries: repository)(petar), throwsA(isA<RepositoryException>()));
    });
  });

  group('R2 · SubmitLink', () {
    test('with 19 analyses today, sends the link and returns what the repository decided', () async {
      final repository = InMemoryEntryRepository(analysed(petar, 19));

      final result = await SubmitLink(entries: repository, clock: clock)(link, by: petar);

      expect(repository.submitCount, 1);
      expect(result.valueOrNull?.single.status, isA<Queued>());
    });

    test('with 20 analyses today, answers at once and sends nothing', () async {
      final repository = InMemoryEntryRepository(analysed(petar, 20));

      final result = await SubmitLink(entries: repository, clock: clock)(link, by: petar);

      expect(result.errorOrNull, isA<DailyLimitReached>());
      expect(repository.submitCount, 0);
    });

    test('analyses older than 24 hours do not count', () async {
      final repository = InMemoryEntryRepository(analysed(petar, 20, ago: const Duration(hours: 25)));

      final result = await SubmitLink(entries: repository, clock: clock)(link, by: petar);

      expect(result.isSuccess, isTrue);
    });

    test('other users\' analyses do not count against the limit', () async {
      final repository = InMemoryEntryRepository(analysed(ana, 20));

      final result = await SubmitLink(entries: repository, clock: clock)(link, by: petar);

      expect(result.isSuccess, isTrue);
    });

    test('a rule that fails in the repository (the server) is returned as it is', () async {
      final availableAt = now.add(const Duration(hours: 3));
      final repository = InMemoryEntryRepository()
        ..nextSubmitResult = Failure(DailyLimitReached(availableAt: availableAt));

      final result = await SubmitLink(entries: repository, clock: clock)(link, by: petar);

      expect(result, Failure<List<Entry>>(DailyLimitReached(availableAt: availableAt)));
    });

    test('lets a lost connection through to the caller', () async {
      final repository = InMemoryEntryRepository()..failNextCall = true;

      await expectLater(
        SubmitLink(entries: repository, clock: clock)(link, by: petar),
        throwsA(isA<RepositoryException>()),
      );
    });
  });

  group('AnalysisOutcome', () {
    test('is either the items of the video or the reason there are none', () {
      String describe(AnalysisOutcome outcome) => switch (outcome) {
        AnalysisSucceeded(:final result) => '${result.items.length} items',
        AnalysisFailedWith(:final reason) => reason.name,
      };

      const recipe = RecipeContent(title: 'Palačinke', ingredients: [], steps: [], servings: 4);
      expect(describe(AnalysisSucceeded(AnalysisResult(link: link, items: const [recipe]))), '1 items');
      expect(describe(const AnalysisFailedWith(AnalysisFailure.notFood)), 'notFood');
    });
  });
}
