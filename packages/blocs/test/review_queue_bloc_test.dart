import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/in_memory_review_queue.dart';

void main() {
  const editor = User(id: UserId('urednik'), role: Role.editor);
  final at = DateTime.utc(2026, 11, 4, 12);

  Entry proposal(String id) => Entry(
    id: EntryId(id),
    owner: const UserId('ana'),
    source: const Manual(),
    status: PendingApproval(submittedAt: at),
    createdAt: at,
    content: RecipeContent(title: 'Recept $id', ingredients: const [], steps: const [], servings: 2),
  );

  ReviewItem item(String id) => ReviewItem.of(proposal(id), catalog: const [])!;

  ReviewQueueBloc blocWith(ReviewQueueRepository queue, {User user = editor}) => ReviewQueueBloc(
    loadQueue: LoadReviewQueue(queue: queue),
    editor: user,
  );

  group('ReviewQueueBloc · four states', () {
    test('starts in loading, so the first frame shows empty rows', () {
      expect(blocWith(InMemoryReviewQueue()).state, const ReviewQueueLoading());
    });

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'shows the proposals, and an editor may decide on them',
      build: () => blocWith(InMemoryReviewQueue([proposal('e-1')])),
      act: (bloc) => bloc.add(const ReviewQueueRequested()),
      expect: () => [
        const ReviewQueueLoading(),
        ReviewQueueLoaded([item('e-1')], canDecide: true),
      ],
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'does not let a user decide',
      build: () => blocWith(
        InMemoryReviewQueue([proposal('e-1')]),
        user: const User(id: UserId('ana'), role: Role.user),
      ),
      act: (bloc) => bloc.add(const ReviewQueueRequested()),
      expect: () => [
        const ReviewQueueLoading(),
        ReviewQueueLoaded([item('e-1')]),
      ],
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'shows the empty queue when nothing waits for a decision',
      build: () => blocWith(InMemoryReviewQueue()),
      act: (bloc) => bloc.add(const ReviewQueueRequested()),
      expect: () => [const ReviewQueueLoading(), const ReviewQueueEmpty()],
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'shows the failure, and "Pokušaj ponovo" loads the proposals',
      build: () => blocWith(InMemoryReviewQueue([proposal('e-1')])..failNextCall = true),
      act: (bloc) async {
        bloc.add(const ReviewQueueRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ReviewQueueRequested());
      },
      expect: () => [
        const ReviewQueueLoading(),
        isA<ReviewQueueFailure>(),
        const ReviewQueueLoading(),
        ReviewQueueLoaded([item('e-1')], canDecide: true),
      ],
    );
  });
}
