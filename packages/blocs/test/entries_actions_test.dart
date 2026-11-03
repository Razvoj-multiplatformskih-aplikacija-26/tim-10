import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/entries_bloc_for.dart';
import 'support/in_memory_entry_repository.dart';

void main() {
  const petar = User(id: UserId('u-petar'), role: Role.user);
  final earlier = DateTime.utc(2026, 11, 4, 10);
  final now = DateTime.utc(2026, 11, 4, 12);
  const recipe = RecipeContent(title: 'Palačinke', ingredients: [], steps: [], servings: 4);

  Entry entry(String id, EntryStatus status) => Entry(
    id: EntryId(id),
    owner: petar.id,
    source: const Manual(),
    status: status,
    createdAt: earlier,
    content: recipe,
  );

  final awaiting = entry('e-1', AwaitingReview(analyzedAt: earlier));
  final analyzing = entry('e-2', Analyzing(startedAt: earlier));
  final library = [awaiting, analyzing];

  EntriesBloc blocWith(InMemoryEntryRepository repository) =>
      entriesBlocFor(repository, user: petar, clock: FixedClock(now));

  group('EntriesBloc · actions', () {
    blocTest<EntriesBloc, EntriesState>(
      '"Sačuvaj" marks the entry busy, then shows the saved entry with a notice',
      build: () => blocWith(InMemoryEntryRepository(library)),
      seed: () => EntriesLoaded(library),
      act: (bloc) => bloc.add(const EntryActionRequested(EntryAction.save, EntryId('e-1'))),
      expect: () => [
        EntriesLoaded(library, busyId: const EntryId('e-1')),
        isA<EntriesLoaded>()
            .having((s) => s.isBusy, 'isBusy', isFalse)
            .having((s) => s.entries.map((e) => e.status), 'statuses', contains(Saved(at: now)))
            .having((s) => s.notice, 'notice', isA<EntryActionSucceeded>()),
      ],
    );

    blocTest<EntriesBloc, EntriesState>(
      'a rule that says no becomes a notice, and the list stays as it was (R3)',
      build: () => blocWith(InMemoryEntryRepository(library)),
      seed: () => EntriesLoaded(library),
      act: (bloc) => bloc.add(const EntryActionRequested(EntryAction.delete, EntryId('e-2'))),
      expect: () => [
        EntriesLoaded(library, busyId: const EntryId('e-2')),
        EntriesLoaded(library, notice: const EntryActionRejected(EntryAction.delete, EntryBeingAnalyzed())),
      ],
    );

    blocTest<EntriesBloc, EntriesState>(
      'a lost connection becomes a notice that can send the same action again',
      build: () => blocWith(InMemoryEntryRepository(library)..failNextCall = true),
      seed: () => EntriesLoaded(library),
      act: (bloc) => bloc.add(const EntryActionRequested(EntryAction.save, EntryId('e-1'))),
      expect: () => [
        EntriesLoaded(library, busyId: const EntryId('e-1')),
        isA<EntriesLoaded>().having(
          (s) => s.notice,
          'notice',
          isA<EntryActionFailed>()
              .having((n) => n.id, 'id', const EntryId('e-1'))
              .having((n) => n.cause, 'cause', isA<RepositoryException>()),
        ),
      ],
    );

    blocTest<EntriesBloc, EntriesState>(
      '"Obriši" removes the entry from the list',
      build: () => blocWith(InMemoryEntryRepository(library)),
      seed: () => EntriesLoaded(library),
      act: (bloc) => bloc.add(const EntryActionRequested(EntryAction.delete, EntryId('e-1'))),
      skip: 1,
      expect: () => [
        EntriesLoaded([analyzing], notice: EntryActionSucceeded(EntryAction.delete, awaiting)),
      ],
    );

    blocTest<EntriesBloc, EntriesState>(
      'a second tap while an action runs is ignored',
      build: () => blocWith(InMemoryEntryRepository(library)),
      seed: () => EntriesLoaded(library),
      act: (bloc) => bloc
        ..add(const EntryActionRequested(EntryAction.save, EntryId('e-1')))
        ..add(const EntryActionRequested(EntryAction.delete, EntryId('e-1'))),
      expect: () => [
        EntriesLoaded(library, busyId: const EntryId('e-1')),
        isA<EntriesLoaded>().having(
          (s) => s.notice,
          'notice',
          isA<EntryActionSucceeded>().having((n) => n.action, 'action', EntryAction.save),
        ),
      ],
    );

    blocTest<EntriesBloc, EntriesState>(
      'acknowledging the notice clears it',
      build: () => blocWith(InMemoryEntryRepository(library)),
      seed: () => EntriesLoaded(library, notice: EntryActionSucceeded(EntryAction.save, awaiting)),
      act: (bloc) => bloc.add(const EntriesNoticeAcknowledged()),
      expect: () => [EntriesLoaded(library)],
    );
  });
}
