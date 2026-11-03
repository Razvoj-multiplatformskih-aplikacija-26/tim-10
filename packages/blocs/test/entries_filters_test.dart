import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/entries_bloc_for.dart';
import 'support/in_memory_entry_repository.dart';

void main() {
  const petar = User(id: UserId('u-petar'), role: Role.user);
  final at = DateTime.utc(2026, 11, 4, 10);
  const recipe = RecipeContent(title: 'Palačinke', ingredients: [], steps: [], servings: 4);
  const restaurant = RestaurantContent(
    name: 'Paprika',
    location: Location(address: 'Cetinjska 15', city: 'Beograd'),
    cuisine: 'srpska',
    recommendedDishes: [],
  );

  Entry entry(String id, EntryStatus status, [EntryContent? content]) =>
      Entry(id: EntryId(id), owner: petar.id, source: const Manual(), status: status, createdAt: at, content: content);

  final reviewRecipe = entry('review-recipe', AwaitingReview(analyzedAt: at), recipe);
  final reviewPlace = entry('review-place', AwaitingReview(analyzedAt: at), restaurant);
  final savedRecipe = entry('saved-recipe', Saved(at: at), recipe);
  final queued = entry('queued', Queued(at: at));
  final failed = entry('failed', AnalysisFailed(reason: AnalysisFailure.timeout, at: at));
  final library = [reviewRecipe, reviewPlace, savedRecipe, queued, failed];

  List<String> ids(List<Entry> entries) => [for (final e in entries) e.id.value];

  group('statusFilterOf', () {
    test('puts each of the eight states under one of the five chips', () {
      const editor = UserId('u-editor');
      expect(statusFilterOf(Queued(at: at)), StatusFilter.processing);
      expect(statusFilterOf(Analyzing(startedAt: at)), StatusFilter.processing);
      expect(statusFilterOf(AnalysisFailed(reason: AnalysisFailure.notFood, at: at)), StatusFilter.processing);
      expect(statusFilterOf(AwaitingReview(analyzedAt: at)), StatusFilter.forReview);
      expect(statusFilterOf(Saved(at: at)), StatusFilter.saved);
      expect(statusFilterOf(PendingApproval(submittedAt: at)), StatusFilter.catalog);
      expect(statusFilterOf(Published(by: editor, at: at, catalogId: const EntryId('c'))), StatusFilter.catalog);
      expect(
        statusFilterOf(Rejected(by: editor, reason: RejectionReason.parse('x').valueOrNull!, at: at)),
        StatusFilter.rejected,
      );
    });
  });

  group('EntriesLoaded · filters', () {
    test('with no filter every entry is visible', () {
      expect(ids(EntriesLoaded(library).visible), ids(library));
    });

    test('"Recepti" hides restaurants and entries without content yet', () {
      final state = EntriesLoaded(library, kind: KindFilter.recipes);

      expect(ids(state.visible), ['review-recipe', 'saved-recipe']);
    });

    test('"U obradi" shows waiting, analysing and failed entries', () {
      final state = EntriesLoaded(library, status: StatusFilter.processing);

      expect(ids(state.visible), ['queued', 'failed']);
    });

    test('the chips count within the selected segment', () {
      expect(EntriesLoaded(library).countFor(StatusFilter.forReview), 2);
      expect(EntriesLoaded(library, kind: KindFilter.restaurants).countFor(StatusFilter.forReview), 1);
      expect(EntriesLoaded(library).countFor(StatusFilter.processing), 2);
      expect(EntriesLoaded(library).forReviewCount, 2);
    });
  });

  group('EntriesBloc · filters', () {
    EntriesBloc blocWith(InMemoryEntryRepository repository) =>
        entriesBlocFor(repository, user: petar, clock: FixedClock(at));

    blocTest<EntriesBloc, EntriesState>(
      'picking a segment and a chip filters the list',
      build: () => blocWith(InMemoryEntryRepository(library)),
      seed: () => EntriesLoaded(library),
      act: (bloc) => bloc
        ..add(const EntriesKindFilterChanged(KindFilter.recipes))
        ..add(const EntriesStatusFilterToggled(StatusFilter.forReview)),
      expect: () => [
        EntriesLoaded(library, kind: KindFilter.recipes),
        EntriesLoaded(library, kind: KindFilter.recipes, status: StatusFilter.forReview),
      ],
    );

    blocTest<EntriesBloc, EntriesState>(
      'tapping the selected chip again shows all states',
      build: () => blocWith(InMemoryEntryRepository(library)),
      seed: () => EntriesLoaded(library, status: StatusFilter.saved),
      act: (bloc) => bloc.add(const EntriesStatusFilterToggled(StatusFilter.saved)),
      expect: () => [EntriesLoaded(library)],
    );

    blocTest<EntriesBloc, EntriesState>(
      'the filters stay after "Sačuvaj" reloads the list',
      build: () => blocWith(InMemoryEntryRepository(library)),
      seed: () => EntriesLoaded(library, kind: KindFilter.recipes, status: StatusFilter.forReview),
      act: (bloc) => bloc.add(const EntryActionRequested(EntryAction.save, EntryId('review-recipe'))),
      skip: 1,
      expect: () => [
        isA<EntriesLoaded>()
            .having((s) => s.kind, 'kind', KindFilter.recipes)
            .having((s) => s.status, 'status', StatusFilter.forReview)
            .having((s) => ids(s.visible), 'visible', isEmpty), // the saved recipe left "Za pregled"
      ],
    );
  });
}
