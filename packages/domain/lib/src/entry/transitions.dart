import '../errors.dart';
import '../result.dart';
import '../user.dart';
import 'access_policy.dart';
import 'entry.dart';
import 'entry_status.dart';

// Every action has the same order of checks: who may do it (AccessPolicy), then whether the state allows it
// (canTransition), then the new entry. Time comes in as `now` and is stored in UTC.

/// "Sačuvaj": the owner keeps the analysed result. `AwaitingReview → Saved`.
Result<Entry> saveEntry(Entry entry, {required User by, required DateTime now}) =>
    _moveTo(entry, Saved(at: now.toUtc()), allowed: AccessPolicy.canManage(by, entry));

/// "Predloži za katalog": the owner proposes a saved entry, or proposes it again after a rejection.
/// `Saved/Rejected → PendingApproval`.
Result<Entry> proposeEntry(Entry entry, {required User by, required DateTime now}) =>
    _moveTo(entry, PendingApproval(submittedAt: now.toUtc()), allowed: AccessPolicy.canManage(by, entry));

/// "Pokušaj ponovo": the owner sends a failed link back to the analysis. `AnalysisFailed → Queued`.
///
/// A retry counts toward the daily limit (R2). The limit depends on all of the user's entries, so it is checked by
/// the use case or the repository with `remainingAnalyses`, not here.
Result<Entry> retryAnalysis(Entry entry, {required User by, required DateTime now}) =>
    _moveTo(entry, Queued(at: now.toUtc()), allowed: AccessPolicy.canManage(by, entry));

Result<Entry> _moveTo(Entry entry, EntryStatus next, {required bool allowed}) {
  if (!allowed) return const Failure(NotAllowed());
  if (!canTransition(entry.status, next)) return Failure(InvalidTransition(from: entry.status, to: next));
  return Success(entry.copyWith(status: next));
}
