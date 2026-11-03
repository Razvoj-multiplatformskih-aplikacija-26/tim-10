import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/in_memory_review_queue.dart';

void main() {
  const editor = User(id: UserId('urednik'), role: Role.editor);
  const ana = User(id: UserId('ana'), role: Role.user);
  final at = DateTime.utc(2026, 11, 4, 12);
  final clock = FixedClock(at);
  const proposalId = EntryId('e-1');

  final proposal = Entry(
    id: proposalId,
    owner: ana.id,
    source: const Manual(),
    status: PendingApproval(submittedAt: at),
    createdAt: at,
    content: const RecipeContent(title: 'Šakšuka', ingredients: [], steps: [], servings: 2),
    personal: const PersonalLayer(note: 'samo za Anu'),
  );

  group('LoadReviewQueue', () {
    test('returns the proposals as rows', () async {
      final items = await LoadReviewQueue(queue: InMemoryReviewQueue([proposal]))();

      expect(items.map((item) => item.id), [proposalId]);
    });

    test('lets the failure of the port through', () {
      final queue = InMemoryReviewQueue([proposal])..failNextCall = true;

      expect(LoadReviewQueue(queue: queue)(), throwsA(isA<RepositoryException>()));
    });
  });

  group('PublishProposal', () {
    test('publishes the proposal and stores it', () async {
      final queue = InMemoryReviewQueue([proposal]);

      final result = await PublishProposal(queue: queue, clock: clock)(proposalId, by: editor);

      final published = Published(by: editor.id, at: at, catalogId: proposalId);
      expect(result.valueOrNull?.status, published);
      expect(queue.entry(proposalId)?.status, published);
    });

    test('says NotFound for a proposal that no longer exists', () async {
      final result = await PublishProposal(queue: InMemoryReviewQueue(), clock: clock)(proposalId, by: editor);

      expect(result, const Failure<Entry>(NotFound()));
    });

    test('does not let a user publish, and stores nothing', () async {
      final queue = InMemoryReviewQueue([proposal]);

      final result = await PublishProposal(queue: queue, clock: clock)(proposalId, by: ana);

      expect(result, const Failure<Entry>(NotAllowed()));
      expect(queue.entry(proposalId)?.status, proposal.status);
    });
  });
}
