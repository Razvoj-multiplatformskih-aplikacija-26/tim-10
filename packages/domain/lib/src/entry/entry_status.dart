import 'package:meta/meta.dart';

import '../identifiers.dart';
import 'rejection_reason.dart';

/// Why the analysis of a video failed.
enum AnalysisFailure { unavailable, notFood, unsupported, timeout }

/// The state of an entry (README). Each state carries only its own data, always including when it started.
sealed class EntryStatus {
  const EntryStatus();

  /// R3 (README: "an entry being processed cannot be changed"). Our reading: waiting for the analysis counts too,
  /// because the link is already with the server and a change could clash with an analysis that is just starting.
  bool get isBeingAnalyzed => switch (this) {
    Queued() || Analyzing() => true,
    AwaitingReview() || Saved() || AnalysisFailed() || PendingApproval() || Published() || Rejected() => false,
  };
}

/// Waiting for analysis: the link is with the server, the analysis has not started yet.
@immutable
final class Queued extends EntryStatus {
  const Queued({required this.at});

  final DateTime at;

  @override
  bool operator ==(Object other) => other is Queued && other.at == at;

  @override
  int get hashCode => at.hashCode;
}

/// Being analysed.
@immutable
final class Analyzing extends EntryStatus {
  const Analyzing({required this.startedAt});

  final DateTime startedAt;

  @override
  bool operator ==(Object other) => other is Analyzing && other.startedAt == startedAt;

  @override
  int get hashCode => startedAt.hashCode;
}

/// The analysis is done and waits for the user to look at it.
@immutable
final class AwaitingReview extends EntryStatus {
  const AwaitingReview({required this.analyzedAt});

  final DateTime analyzedAt;

  @override
  bool operator ==(Object other) => other is AwaitingReview && other.analyzedAt == analyzedAt;

  @override
  int get hashCode => analyzedAt.hashCode;
}

/// Saved by the user, in their personal library.
@immutable
final class Saved extends EntryStatus {
  const Saved({required this.at});

  final DateTime at;

  @override
  bool operator ==(Object other) => other is Saved && other.at == at;

  @override
  int get hashCode => at.hashCode;
}

/// The analysis failed; the entry has no content.
@immutable
final class AnalysisFailed extends EntryStatus {
  const AnalysisFailed({required this.reason, required this.at});

  final AnalysisFailure reason;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is AnalysisFailed && other.reason == reason && other.at == at;

  @override
  int get hashCode => Object.hash(reason, at);
}

/// Proposed for the catalog, waiting for an editor's decision.
@immutable
final class PendingApproval extends EntryStatus {
  const PendingApproval({required this.submittedAt});

  final DateTime submittedAt;

  @override
  bool operator ==(Object other) => other is PendingApproval && other.submittedAt == submittedAt;

  @override
  int get hashCode => submittedAt.hashCode;
}

/// Published in the catalog by an editor.
///
/// [catalogId] is the catalog record. When a proposal is merged into an existing restaurant (R5), it is the id of
/// that existing record, so merging needs no state of its own.
@immutable
final class Published extends EntryStatus {
  const Published({required this.by, required this.at, required this.catalogId});

  final UserId by;
  final DateTime at;
  final EntryId catalogId;

  @override
  bool operator ==(Object other) =>
      other is Published && other.by == by && other.at == at && other.catalogId == catalogId;

  @override
  int get hashCode => Object.hash(by, at, catalogId);
}

/// Rejected by an editor; the user sees the reason and may propose the entry again.
@immutable
final class Rejected extends EntryStatus {
  const Rejected({required this.by, required this.reason, required this.at});

  final UserId by;
  final RejectionReason reason;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is Rejected && other.by == by && other.reason == reason && other.at == at;

  @override
  int get hashCode => Object.hash(by, reason, at);
}

/// The only place that says which state may follow which: 11 of the 64 pairs.
bool canTransition(EntryStatus from, EntryStatus to) => switch ((from, to)) {
  (Queued(), Analyzing()) => true, // the server starts the analysis
  (Queued() || Analyzing(), AnalysisFailed()) => true, // video unavailable, not food, timeout
  (Analyzing(), AwaitingReview()) => true, // the AI result is ready
  (Queued(), AwaitingReview()) => true, // the same video was already analysed: the result is copied at once (R4)
  (AwaitingReview(), Saved()) => true, // the user looks at the result and saves it
  (AnalysisFailed(), Queued()) => true, // retry (counts toward the daily limit)
  (Saved() || Rejected(), PendingApproval()) => true, // proposed for the catalog (again, after a rejection)
  (PendingApproval(), Published() || Rejected()) => true, // the editor's decision
  _ => false,
};
