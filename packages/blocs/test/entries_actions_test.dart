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

  EntriesBloc blocWith(EntryRepository repository) => entriesBlocFor(repository, user: petar, clock: FixedClock(now));

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
        EntriesLoaded(
          [analyzing],
          actions: {analyzing.id: const <EntryAction>{}}, // nothing while it is being analysed (R3)
          notice: EntryActionSucceeded(EntryAction.delete, awaiting),
        ),
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

    test('each card gets exactly the buttons the domain allows', () async {
      const editor = UserId('u-editor');
      final reason = RejectionReason.parse('Fale koraci.').valueOrNull!;
      final all = [
        entry('queued', Queued(at: earlier)),
        entry('analyzing', Analyzing(startedAt: earlier)),
        entry('awaiting', AwaitingReview(analyzedAt: earlier)),
        entry('saved', Saved(at: earlier)),
        entry('failed', AnalysisFailed(reason: AnalysisFailure.notFood, at: earlier)),
        entry('pending', PendingApproval(submittedAt: earlier)),
        entry('published', Published(by: editor, at: earlier, catalogId: const EntryId('c-1'))),
        entry('rejected', Rejected(by: editor, reason: reason, at: earlier)),
      ];
      final bloc = blocWith(InMemoryEntryRepository(all))..add(const EntriesRequested());

      final loaded = await bloc.stream.firstWhere((s) => s is EntriesLoaded) as EntriesLoaded;

      expect(loaded.actions, {
        const EntryId('queued'): <EntryAction>{},
        const EntryId('analyzing'): <EntryAction>{},
        const EntryId('awaiting'): {EntryAction.save, EntryAction.delete},
        const EntryId('saved'): {EntryAction.propose, EntryAction.delete},
        const EntryId('failed'): {EntryAction.retry, EntryAction.delete},
        const EntryId('pending'): {EntryAction.delete},
        const EntryId('published'): {EntryAction.delete},
        const EntryId('rejected'): {EntryAction.propose, EntryAction.delete},
      });
      await bloc.close();
    });

    test('another user\'s entry would get no buttons at all', () async {
      final anas = Entry(
        id: const EntryId('ana-1'),
        owner: const UserId('u-ana'),
        source: const Manual(),
        status: Saved(at: earlier),
        createdAt: earlier,
      );
      // The repository would never give Ana's entry to Petar; this only shows that the domain also says no.
      final bloc = blocWith(_EveryoneRepository([anas]))..add(const EntriesRequested());

      final loaded = await bloc.stream.firstWhere((s) => s is EntriesLoaded) as EntriesLoaded;

      expect(loaded.actionsFor(const EntryId('ana-1')), isEmpty);
      await bloc.close();
    });

    blocTest<EntriesBloc, EntriesState>(
      'acknowledging the notice clears it',
      build: () => blocWith(InMemoryEntryRepository(library)),
      seed: () => EntriesLoaded(library, notice: EntryActionSucceeded(EntryAction.save, awaiting)),
      act: (bloc) => bloc.add(const EntriesNoticeAcknowledged()),
      expect: () => [EntriesLoaded(library)],
    );

    blocTest<EntriesBloc, EntriesState>(
      'deleting the last entry leads to the empty state and still says so',
      build: () => blocWith(InMemoryEntryRepository([awaiting])),
      seed: () => EntriesLoaded([awaiting]),
      act: (bloc) => bloc.add(const EntryActionRequested(EntryAction.delete, EntryId('e-1'))),
      skip: 1,
      expect: () => [isA<EntriesEmpty>().having((s) => s.notice, 'notice', isA<EntryActionSucceeded>())],
    );

    blocTest<EntriesBloc, EntriesState>(
      'acknowledging the notice on the empty state clears it',
      build: () => blocWith(InMemoryEntryRepository(const [])),
      seed: () => EntriesEmpty(notice: EntryActionSucceeded(EntryAction.delete, awaiting)),
      act: (bloc) => bloc.add(const EntriesNoticeAcknowledged()),
      expect: () => [const EntriesEmpty()],
    );

    test('filters from before the empty state do not hide the first new entry', () async {
      final repository = InMemoryEntryRepository([awaiting]);
      final bloc = blocWith(repository)..add(const EntriesRequested());
      await bloc.stream.firstWhere((state) => state is EntriesLoaded);
      bloc.add(const EntriesStatusFilterToggled(StatusFilter.forReview));
      await bloc.stream.first;
      bloc.add(const EntriesRequested());
      await bloc.stream.firstWhere((state) => state is EntriesLoaded);

      bloc.add(const EntryActionRequested(EntryAction.delete, EntryId('e-1')));
      await bloc.stream.firstWhere((state) => state is EntriesEmpty);
      await repository.save(analyzing);
      bloc.add(const EntriesRequested());
      final loaded = await bloc.stream.firstWhere((state) => state is EntriesLoaded) as EntriesLoaded;

      expect(loaded.status, isNull);
      await bloc.close();
    });
  });
}

/// A repository that, wrongly, gives everyone's entries to anyone: only for the test above.
final class _EveryoneRepository implements EntryRepository {
  _EveryoneRepository(this._entries);

  final List<Entry> _entries;

  @override
  Future<List<Entry>> entriesOf(UserId owner) async => _entries;

  @override
  Future<Entry?> find(EntryId id) => throw UnimplementedError();

  @override
  Future<Result<List<Entry>>> submitLink(VideoLink link, {required UserId owner}) => throw UnimplementedError();

  @override
  Future<Entry> save(Entry entry) => throw UnimplementedError();

  @override
  Future<void> delete(EntryId id) => throw UnimplementedError();
}
