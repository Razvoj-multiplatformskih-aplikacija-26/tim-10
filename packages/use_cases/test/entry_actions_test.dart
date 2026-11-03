import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/in_memory_entry_repository.dart';

void main() {
  final earlier = DateTime.utc(2026, 11, 4, 10);
  final now = DateTime.utc(2026, 11, 4, 12);
  final clock = FixedClock(now);
  const petar = User(id: UserId('u-petar'), role: Role.user);
  const ana = User(id: UserId('u-ana'), role: Role.user);
  const recipe = RecipeContent(title: 'Palačinke', ingredients: [], steps: [], servings: 4);

  Entry petarsEntry(EntryStatus status) => Entry(
    id: const EntryId('e-1'),
    owner: petar.id,
    source: const Manual(),
    status: status,
    createdAt: earlier,
    content: recipe,
  );

  group('SaveEntry', () {
    test('saves an analysed entry and stores it', () async {
      final repository = InMemoryEntryRepository([petarsEntry(AwaitingReview(analyzedAt: earlier))]);

      final result = await SaveEntry(entries: repository, clock: clock)(const EntryId('e-1'), by: petar);

      expect(result.valueOrNull?.status, Saved(at: now));
      expect((await repository.find(const EntryId('e-1')))?.status, Saved(at: now));
    });

    test('stores nothing when the domain says no', () async {
      final queued = petarsEntry(Queued(at: earlier));
      final repository = InMemoryEntryRepository([queued]);

      final result = await SaveEntry(entries: repository, clock: clock)(const EntryId('e-1'), by: petar);

      expect(result.errorOrNull, isA<InvalidTransition>());
      expect(await repository.find(const EntryId('e-1')), queued);
    });

    test('another user may not save it', () async {
      final repository = InMemoryEntryRepository([petarsEntry(AwaitingReview(analyzedAt: earlier))]);

      final result = await SaveEntry(entries: repository, clock: clock)(const EntryId('e-1'), by: ana);

      expect(result, const Failure<Entry>(NotAllowed()));
    });

    test('an entry that does not exist is NotFound', () async {
      final result = await SaveEntry(entries: InMemoryEntryRepository(), clock: clock)(
        const EntryId('missing'),
        by: petar,
      );

      expect(result, const Failure<Entry>(NotFound()));
    });
  });

  group('R2 · RetryAnalysis', () {
    final failed = petarsEntry(AnalysisFailed(reason: AnalysisFailure.timeout, at: earlier))
        .copyWith(analysisRequests: [earlier]);

    /// [count] other entries of Petar, each with one analysis an hour ago.
    List<Entry> otherAnalyses(int count) => [
      for (var i = 0; i < count; i++)
        Entry(
          id: EntryId('other-$i'),
          owner: petar.id,
          source: const Manual(),
          status: Saved(at: earlier),
          createdAt: earlier,
          analysisRequests: [now.subtract(const Duration(hours: 1))],
        ),
    ];

    test('sends a failed link back to the queue and counts the new request', () async {
      final repository = InMemoryEntryRepository([failed]);

      final result = await RetryAnalysis(entries: repository, clock: clock)(const EntryId('e-1'), by: petar);

      expect(result.valueOrNull?.status, Queued(at: now));
      expect((await repository.find(const EntryId('e-1')))?.analysisRequests, [earlier, now]);
    });

    test('with 20 analyses today, answers DailyLimitReached and leaves the entry as it was', () async {
      // The failed entry's own request (2 h ago) plus 19 others: 20 analyses in the last 24 hours.
      final repository = InMemoryEntryRepository([failed, ...otherAnalyses(19)]);

      final result = await RetryAnalysis(entries: repository, clock: clock)(const EntryId('e-1'), by: petar);

      expect(result.errorOrNull, isA<DailyLimitReached>());
      expect(await repository.find(const EntryId('e-1')), failed);
    });

    test('an entry that did not fail is told so, not that the limit is reached', () async {
      final repository = InMemoryEntryRepository([petarsEntry(Saved(at: earlier)), ...otherAnalyses(20)]);

      final result = await RetryAnalysis(entries: repository, clock: clock)(const EntryId('e-1'), by: petar);

      expect(result.errorOrNull, isA<InvalidTransition>());
    });

    test('an entry that does not exist is NotFound', () async {
      final result = await RetryAnalysis(entries: InMemoryEntryRepository(), clock: clock)(
        const EntryId('missing'),
        by: petar,
      );

      expect(result, const Failure<Entry>(NotFound()));
    });
  });

  group('R3 · DeleteEntry', () {
    test('removes a saved entry and returns it', () async {
      final saved = petarsEntry(Saved(at: earlier));
      final repository = InMemoryEntryRepository([saved]);

      final result = await DeleteEntry(entries: repository)(const EntryId('e-1'), by: petar);

      expect(result, Success(saved));
      expect(await repository.find(const EntryId('e-1')), isNull);
    });

    test('keeps an entry that is being analysed', () async {
      final analyzing = petarsEntry(Analyzing(startedAt: earlier));
      final repository = InMemoryEntryRepository([analyzing]);

      final result = await DeleteEntry(entries: repository)(const EntryId('e-1'), by: petar);

      expect(result, const Failure<Entry>(EntryBeingAnalyzed()));
      expect(await repository.find(const EntryId('e-1')), analyzing);
    });

    test('another user may not delete it', () async {
      final repository = InMemoryEntryRepository([petarsEntry(Saved(at: earlier))]);

      final result = await DeleteEntry(entries: repository)(const EntryId('e-1'), by: ana);

      expect(result, const Failure<Entry>(NotAllowed()));
      expect(await repository.find(const EntryId('e-1')), isNotNull);
    });

    test('an entry that does not exist is NotFound', () async {
      final result = await DeleteEntry(entries: InMemoryEntryRepository())(const EntryId('missing'), by: petar);

      expect(result, const Failure<Entry>(NotFound()));
    });
  });

  group('ProposeEntry', () {
    test('proposes a saved entry and stores it', () async {
      final repository = InMemoryEntryRepository([petarsEntry(Saved(at: earlier))]);

      final result = await ProposeEntry(entries: repository, clock: clock)(const EntryId('e-1'), by: petar);

      expect(result.valueOrNull?.status, PendingApproval(submittedAt: now));
      expect((await repository.find(const EntryId('e-1')))?.status, PendingApproval(submittedAt: now));
    });

    test('stores nothing when the entry is not saved yet', () async {
      final awaiting = petarsEntry(AwaitingReview(analyzedAt: earlier));
      final repository = InMemoryEntryRepository([awaiting]);

      final result = await ProposeEntry(entries: repository, clock: clock)(const EntryId('e-1'), by: petar);

      expect(result.errorOrNull, isA<InvalidTransition>());
      expect(await repository.find(const EntryId('e-1')), awaiting);
    });

    test('an entry that does not exist is NotFound', () async {
      final result = await ProposeEntry(entries: InMemoryEntryRepository(), clock: clock)(
        const EntryId('missing'),
        by: petar,
      );

      expect(result, const Failure<Entry>(NotFound()));
    });
  });
}
