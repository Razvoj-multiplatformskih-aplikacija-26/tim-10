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

  group('ReviewQueueBloc · cursor and panel', () {
    final items = [item('e-1'), item('e-2'), item('e-3')];
    final queue = ReviewQueueLoaded(items, canDecide: true);

    ReviewQueueBloc three() => blocWith(InMemoryReviewQueue([proposal('e-1'), proposal('e-2'), proposal('e-3')]));

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'moves the cursor down and up',
      build: three,
      seed: () => queue,
      act: (bloc) => bloc
        ..add(const ReviewCursorMoved(1))
        ..add(const ReviewCursorMoved(1))
        ..add(const ReviewCursorMoved(-1)),
      expect: () => [queue.withCursor(1), queue.withCursor(2), queue.withCursor(1)],
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'stops at the first row and at the last row',
      build: three,
      seed: () => queue.withCursor(2),
      act: (bloc) => bloc
        ..add(const ReviewCursorMoved(1))
        ..add(const ReviewCursorMoved(-5)),
      expect: () => [queue],
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'Enter opens the row under the cursor, and Esc closes the panel without moving the cursor',
      build: three,
      seed: () => queue.withCursor(1),
      act: (bloc) => bloc
        ..add(const ReviewCursorActivated())
        ..add(const ReviewPanelClosed()),
      expect: () => [queue.withCursor(1).withPanel(isOpen: true), queue.withCursor(1)],
      verify: (bloc) => expect((bloc.state as ReviewQueueLoaded).selectedId, isNull),
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'the open panel follows the cursor',
      build: three,
      seed: () => queue.withPanel(isOpen: true),
      act: (bloc) => bloc.add(const ReviewCursorMoved(1)),
      verify: (bloc) => expect((bloc.state as ReviewQueueLoaded).selectedId, const EntryId('e-2')),
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'a click opens that row and puts the cursor on it',
      build: three,
      seed: () => queue,
      act: (bloc) => bloc.add(const ReviewItemOpened(EntryId('e-3'))),
      expect: () => [queue.withCursor(2).withPanel(isOpen: true)],
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'a link with a selection opens that proposal after loading',
      build: three,
      act: (bloc) => bloc.add(const ReviewQueueRequested(selected: EntryId('e-2'))),
      expect: () => [const ReviewQueueLoading(), queue.withCursor(1).withPanel(isOpen: true)],
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'an old link to a proposal that is gone opens nothing',
      build: three,
      act: (bloc) => bloc.add(const ReviewQueueRequested(selected: EntryId('e-9'))),
      expect: () => [const ReviewQueueLoading(), queue],
    );
  });

  group('ReviewQueueBloc · decisions', () {
    const first = EntryId('e-1');
    final queue = ReviewQueueLoaded([item('e-1'), item('e-2')], canDecide: true);
    final reason = RejectionReason.parse('Video nije o hrani.').valueOrNull!;

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'publishes, and the next proposal takes the place under the cursor',
      build: () => blocWith(InMemoryReviewQueue([proposal('e-1'), proposal('e-2')])),
      seed: () => queue.withPanel(isOpen: true),
      act: (bloc) => bloc.add(const ProposalPublishRequested(first)),
      expect: () => [
        queue.withPanel(isOpen: true).busyWith(first),
        ReviewQueueLoaded(
          [item('e-2')],
          canDecide: true,
          isPanelOpen: true,
          notice: const ReviewActionSucceeded(ReviewDecision.publish),
        ),
      ],
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'rejects with the reason',
      build: () => blocWith(InMemoryReviewQueue([proposal('e-1'), proposal('e-2')])),
      seed: () => queue,
      act: (bloc) => bloc.add(ProposalRejectRequested(first, reason)),
      skip: 1,
      expect: () => [
        ReviewQueueLoaded([item('e-2')], canDecide: true, notice: const ReviewActionSucceeded(ReviewDecision.reject)),
      ],
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'the cursor moves up when the last row is gone',
      build: () => blocWith(InMemoryReviewQueue([proposal('e-1'), proposal('e-2')])),
      seed: () => queue.withCursor(1),
      act: (bloc) => bloc.add(const ProposalPublishRequested(EntryId('e-2'))),
      skip: 1,
      verify: (bloc) {
        final state = bloc.state as ReviewQueueLoaded;
        expect(state.cursor, 0);
        expect(state.current.id, first);
      },
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'the last decision ends in the empty queue, with its notice',
      build: () => blocWith(InMemoryReviewQueue([proposal('e-1')])),
      seed: () => ReviewQueueLoaded([item('e-1')], canDecide: true),
      act: (bloc) => bloc.add(const ProposalPublishRequested(first)),
      skip: 1,
      expect: () => [const ReviewQueueEmpty(notice: ReviewActionSucceeded(ReviewDecision.publish))],
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'shows the rule that said no, and keeps the queue',
      build: () => blocWith(
        InMemoryReviewQueue([proposal('e-1')]),
        user: const User(id: UserId('ana'), role: Role.user),
      ),
      seed: () => queue,
      act: (bloc) => bloc.add(const ProposalPublishRequested(first)),
      skip: 1,
      expect: () => [queue.withNotice(const ReviewActionRefused(NotAllowed()))],
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'a lost connection keeps the queue and offers the same request again',
      build: () => blocWith(InMemoryReviewQueue([proposal('e-1')])..failNextCall = true),
      seed: () => queue,
      act: (bloc) => bloc.add(const ProposalPublishRequested(first)),
      skip: 1,
      verify: (bloc) {
        final notice = (bloc.state as ReviewQueueLoaded).notice;
        expect(notice, isA<ReviewActionFailed>());
        expect((notice! as ReviewActionFailed).request, isA<ProposalPublishRequested>());
      },
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'ignores a second decision while one is running',
      build: () => blocWith(InMemoryReviewQueue([proposal('e-1'), proposal('e-2')])),
      seed: () => queue.busyWith(first),
      act: (bloc) => bloc.add(const ProposalPublishRequested(EntryId('e-2'))),
      expect: () => <ReviewQueueState>[],
    );

    blocTest<ReviewQueueBloc, ReviewQueueState>(
      'forgets the notice once it is shown',
      build: () => blocWith(InMemoryReviewQueue()),
      seed: () => queue.withNotice(const ReviewActionRefused(NotAllowed())),
      act: (bloc) => bloc.add(const ReviewNoticeAcknowledged()),
      expect: () => [queue],
    );
  });
}
