import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const petar = User(id: UserId('u-petar'), role: Role.user);
  const stefan = User(id: UserId('u-stefan'), role: Role.user);
  const editor = User(id: UserId('u-editor'), role: Role.editor);
  final at = DateTime.utc(2026, 11, 3, 12);

  Entry petarsEntry(EntryStatus status) =>
      Entry(id: const EntryId('e-1'), owner: petar.id, source: const Manual(), status: status, createdAt: at);

  group('R3 · deleteEntry', () {
    for (final status in [Queued(at: at), Analyzing(startedAt: at)]) {
      test('cannot delete an entry in ${status.runtimeType}', () {
        expect(deleteEntry(petarsEntry(status), by: petar), const Failure<Entry>(EntryBeingAnalyzed()));
      });
    }

    for (final status in [
      AwaitingReview(analyzedAt: at),
      Saved(at: at),
      AnalysisFailed(reason: AnalysisFailure.notFood, at: at),
      PendingApproval(submittedAt: at),
      Published(by: editor.id, at: at, catalogId: const EntryId('c-1')),
      Rejected(by: editor.id, reason: RejectionReason.parse('Duplikat.').valueOrNull!, at: at),
    ]) {
      test('can delete an entry in ${status.runtimeType}', () {
        expect(deleteEntry(petarsEntry(status), by: petar), Success(petarsEntry(status)));
      });
    }

    test('another user or an editor may not delete it', () {
      final entry = petarsEntry(Saved(at: at));

      expect(deleteEntry(entry, by: stefan), const Failure<Entry>(NotAllowed()));
      expect(deleteEntry(entry, by: editor), const Failure<Entry>(NotAllowed()));
    });
  });

  group('R3 · isBeingAnalyzed', () {
    test('is true only while waiting for or going through the analysis', () {
      expect(Queued(at: at).isBeingAnalyzed, isTrue);
      expect(Analyzing(startedAt: at).isBeingAnalyzed, isTrue);
      expect(AwaitingReview(analyzedAt: at).isBeingAnalyzed, isFalse);
      expect(AnalysisFailed(reason: AnalysisFailure.timeout, at: at).isBeingAnalyzed, isFalse);
    });
  });
}
