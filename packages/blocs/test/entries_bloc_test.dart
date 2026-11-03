import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/entries_bloc_for.dart';
import 'support/in_memory_entry_repository.dart';

void main() {
  const petar = User(id: UserId('u-petar'), role: Role.user);
  final at = DateTime.utc(2026, 11, 4, 12);
  final saved = Entry(
    id: const EntryId('e-1'),
    owner: petar.id,
    source: const Manual(),
    status: Saved(at: at),
    createdAt: at,
  );

  EntriesBloc blocWith(EntryRepository repository) => entriesBlocFor(repository, user: petar, clock: FixedClock(at));

  group('EntriesBloc · four states', () {
    test('starts in loading, so the first frame shows skeleton cards', () {
      expect(blocWith(InMemoryEntryRepository()).state, const EntriesLoading());
    });

    // A Bloc does not emit a state equal to the current one, except the very first emit: so the first load
    // emits EntriesLoading even though the Bloc already starts in it.
    blocTest<EntriesBloc, EntriesState>(
      'shows the user\'s entries',
      build: () => blocWith(InMemoryEntryRepository([saved])),
      act: (bloc) => bloc.add(const EntriesRequested()),
      expect: () => [
        const EntriesLoading(),
        EntriesLoaded([saved]),
      ],
    );

    blocTest<EntriesBloc, EntriesState>(
      'shows the empty library when the user has no entries',
      build: () => blocWith(InMemoryEntryRepository()),
      act: (bloc) => bloc.add(const EntriesRequested()),
      expect: () => [const EntriesLoading(), const EntriesEmpty()],
    );

    blocTest<EntriesBloc, EntriesState>(
      'shows the failure when the entries cannot be loaded',
      build: () => blocWith(InMemoryEntryRepository([saved])..failNextCall = true),
      act: (bloc) => bloc.add(const EntriesRequested()),
      expect: () => [
        const EntriesLoading(),
        isA<EntriesFailure>().having((s) => s.cause, 'cause', isA<RepositoryException>()),
      ],
    );

    blocTest<EntriesBloc, EntriesState>(
      '"Pokušaj ponovo" after a failure loads again, through loading',
      build: () => blocWith(InMemoryEntryRepository([saved])..failNextCall = true),
      act: (bloc) async {
        bloc.add(const EntriesRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const EntriesRequested());
      },
      expect: () => [
        const EntriesLoading(),
        isA<EntriesFailure>(),
        const EntriesLoading(),
        EntriesLoaded([saved]),
      ],
    );
  });

  group('EntriesBloc · a stale answer', () {
    test('an older load that answers last is dropped', () async {
      final repository = _ControlledRepository();
      final bloc = blocWith(repository);
      final states = <EntriesState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const EntriesRequested()); // first, slow
      bloc.add(const EntriesRequested()); // "Pokušaj ponovo", fast
      await Future<void>.delayed(Duration.zero);

      repository.answers[1].complete([saved]);
      await Future<void>.delayed(Duration.zero);
      repository.answers[0].complete(const []);
      await Future<void>.delayed(Duration.zero);

      expect(states.last, EntriesLoaded([saved]));
      expect(states, isNot(contains(const EntriesEmpty())));

      await subscription.cancel();
      await bloc.close();
    });
  });
}

/// A repository whose answers the test releases by hand, in any order.
final class _ControlledRepository implements EntryRepository {
  final answers = <Completer<List<Entry>>>[];

  @override
  Future<List<Entry>> entriesOf(UserId owner) {
    final answer = Completer<List<Entry>>();
    answers.add(answer);
    return answer.future;
  }

  @override
  Future<Entry?> find(EntryId id) => throw UnimplementedError();

  @override
  Future<Result<List<Entry>>> submitLink(VideoLink link, {required UserId owner}) => throw UnimplementedError();

  @override
  Future<Entry> save(Entry entry) => throw UnimplementedError();

  @override
  Future<void> delete(EntryId id) => throw UnimplementedError();
}
