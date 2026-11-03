import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final at = DateTime.utc(2026, 11, 3, 12);
  const editor = UserId('u-editor');

  final queued = Queued(at: at);
  final analyzing = Analyzing(startedAt: at);
  final awaitingReview = AwaitingReview(analyzedAt: at);
  final saved = Saved(at: at);
  final analysisFailed = AnalysisFailed(reason: AnalysisFailure.notFood, at: at);
  final pendingApproval = PendingApproval(submittedAt: at);
  final published = Published(by: editor, at: at, catalogId: const EntryId('c-1'));
  final rejected = Rejected(by: editor, reason: 'Nije recept.', at: at);

  final all = [queued, analyzing, awaitingReview, saved, analysisFailed, pendingApproval, published, rejected];

  group('R6 · canTransition', () {
    test('allows exactly 11 of the 64 pairs', () {
      final allowed = [
        for (final from in all)
          for (final to in all)
            if (canTransition(from, to)) (from, to),
      ];

      expect(allowed, [
        (queued, analyzing),
        (queued, awaitingReview),
        (queued, analysisFailed),
        (analyzing, awaitingReview),
        (analyzing, analysisFailed),
        (awaitingReview, saved),
        (saved, pendingApproval),
        (analysisFailed, queued),
        (pendingApproval, published),
        (pendingApproval, rejected),
        (rejected, pendingApproval),
      ]);
    });

    test('lets a link skip the analysis when the video was already analysed (R4)', () {
      expect(canTransition(queued, awaitingReview), isTrue);
    });

    test('never leaves the catalog and never stays in the same state', () {
      for (final to in all) {
        expect(canTransition(published, to), isFalse);
      }
      for (final status in all) {
        expect(canTransition(status, status), isFalse);
      }
    });
  });

  group('EntryStatus', () {
    test('states with the same data are equal', () {
      expect(Rejected(by: editor, reason: 'Nije recept.', at: at), rejected);
      expect(Rejected(by: editor, reason: 'Duplikat.', at: at), isNot(rejected));
      expect(Saved(at: at), isNot(Queued(at: at)));
    });
  });
}
