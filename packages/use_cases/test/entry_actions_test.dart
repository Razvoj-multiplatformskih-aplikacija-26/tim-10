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
