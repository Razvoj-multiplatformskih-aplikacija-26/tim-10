import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const petar = User(id: UserId('u-petar'), role: Role.user);
  const stefan = User(id: UserId('u-stefan'), role: Role.user);
  const editor = User(id: UserId('u-editor'), role: Role.editor);

  final earlier = DateTime.utc(2026, 11, 3, 10);
  final now = DateTime.utc(2026, 11, 3, 12);
  const recipe = RecipeContent(title: 'Palačinke', ingredients: [], steps: [], servings: 4);

  Entry petarsEntry(EntryStatus status) => Entry(
    id: const EntryId('e-1'),
    owner: petar.id,
    source: const Manual(),
    status: status,
    createdAt: earlier,
    content: recipe,
  );

  group('R6 · saveEntry', () {
    test('saves an analysed entry', () {
      final result = saveEntry(
        petarsEntry(AwaitingReview(analyzedAt: earlier)),
        by: petar,
        now: now,
      );

      expect(result.valueOrNull?.status, Saved(at: now));
      expect(result.valueOrNull?.content, recipe);
    });

    test('cannot save an entry that is still waiting for the analysis', () {
      final queued = Queued(at: earlier);

      expect(
        saveEntry(petarsEntry(queued), by: petar, now: now),
        Failure<Entry>(
          InvalidTransition(
            from: queued,
            to: Saved(at: now),
          ),
        ),
      );
    });

    test('another user or an editor may not save it', () {
      final entry = petarsEntry(AwaitingReview(analyzedAt: earlier));

      expect(saveEntry(entry, by: stefan, now: now), const Failure<Entry>(NotAllowed()));
      expect(saveEntry(entry, by: editor, now: now), const Failure<Entry>(NotAllowed()));
    });

    test('stores the time in UTC', () {
      final local = DateTime(2026, 11, 3, 13);

      final saved = saveEntry(
        petarsEntry(AwaitingReview(analyzedAt: earlier)),
        by: petar,
        now: local,
      );

      expect((saved.valueOrNull?.status as Saved?)?.at.isUtc, isTrue);
    });
  });

  group('R6 · proposeEntry', () {
    test('proposes a saved entry for the catalog', () {
      final result = proposeEntry(
        petarsEntry(Saved(at: earlier)),
        by: petar,
        now: now,
      );

      expect(result.valueOrNull?.status, PendingApproval(submittedAt: now));
    });

    test('proposes a rejected entry again', () {
      final rejected = Rejected(by: editor.id, reason: RejectionReason.parse('Fale koraci.').valueOrNull!, at: earlier);

      expect(proposeEntry(petarsEntry(rejected), by: petar, now: now).isSuccess, isTrue);
    });

    test('cannot propose an entry that the user has not saved yet', () {
      final result = proposeEntry(
        petarsEntry(AwaitingReview(analyzedAt: earlier)),
        by: petar,
        now: now,
      );

      expect(result.errorOrNull, isA<InvalidTransition>());
    });

    test('another user may not propose it', () {
      expect(
        proposeEntry(
          petarsEntry(Saved(at: earlier)),
          by: stefan,
          now: now,
        ),
        const Failure<Entry>(NotAllowed()),
      );
    });
  });

  group('R2 · retryAnalysis counts as a new analysis request', () {
    test('adds the time of the retry to the earlier requests', () {
      final failed = petarsEntry(AnalysisFailed(reason: AnalysisFailure.timeout, at: earlier))
          .copyWith(analysisRequests: [earlier]);

      final retried = retryAnalysis(failed, by: petar, now: now).valueOrNull;

      expect(retried?.analysisRequests, [earlier, now]);
    });

    test('adds nothing when the retry is not allowed', () {
      final saved = petarsEntry(Saved(at: earlier)).copyWith(analysisRequests: [earlier]);

      expect(retryAnalysis(saved, by: petar, now: now).isSuccess, isFalse);
      expect(saved.analysisRequests, [earlier]);
    });
  });

  group('R6 · retryAnalysis', () {
    test('sends a failed link back to the queue', () {
      final failed = AnalysisFailed(reason: AnalysisFailure.timeout, at: earlier);

      expect(retryAnalysis(petarsEntry(failed), by: petar, now: now).valueOrNull?.status, Queued(at: now));
    });

    test('cannot retry an entry whose analysis did not fail', () {
      final result = retryAnalysis(
        petarsEntry(Saved(at: earlier)),
        by: petar,
        now: now,
      );

      expect(result.errorOrNull, isA<InvalidTransition>());
    });

    test('checks who may do it before the state', () {
      // Wrong user and wrong state at once: the answer is NotAllowed, so a stranger learns nothing about the entry.
      expect(
        retryAnalysis(
          petarsEntry(Saved(at: earlier)),
          by: stefan,
          now: now,
        ),
        const Failure<Entry>(NotAllowed()),
      );
    });
  });

  group('R6 · publishEntry and rejectEntry', () {
    final reason = RejectionReason.parse('Video ne prikazuje pripremu.').valueOrNull!;
    final proposal = petarsEntry(PendingApproval(submittedAt: earlier));

    test('an editor publishes a proposal into the catalog', () {
      final result = publishEntry(proposal, by: editor, now: now, catalogId: const EntryId('c-7'));

      expect(result.valueOrNull?.status, Published(by: editor.id, at: now, catalogId: const EntryId('c-7')));
      expect(result.valueOrNull?.content, recipe);
    });

    test('an editor rejects a proposal with a reason', () {
      final result = rejectEntry(proposal, by: editor, now: now, reason: reason);

      expect(result.valueOrNull?.status, Rejected(by: editor.id, reason: reason, at: now));
    });

    test('a user may not publish, not even their own proposal', () {
      expect(
        publishEntry(proposal, by: petar, now: now, catalogId: const EntryId('c-7')),
        const Failure<Entry>(NotAllowed()),
      );
      expect(rejectEntry(proposal, by: petar, now: now, reason: reason), const Failure<Entry>(NotAllowed()));
    });

    test('an entry that was not proposed cannot be published', () {
      final result = publishEntry(
        petarsEntry(Saved(at: earlier)),
        by: editor,
        now: now,
        catalogId: const EntryId('c-7'),
      );

      expect(result.errorOrNull, isA<InvalidTransition>());
    });

    test('a published entry cannot be rejected afterwards', () {
      final published = publishEntry(proposal, by: editor, now: now, catalogId: const EntryId('c-7')).valueOrNull!;

      expect(rejectEntry(published, by: editor, now: now, reason: reason).errorOrNull, isA<InvalidTransition>());
    });
  });
}
