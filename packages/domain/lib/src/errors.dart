import 'package:meta/meta.dart';

import 'entry/entry_status.dart';

/// Every way a domain rule can fail.
///
/// An error is a type, never a message: the apps turn each error into Serbian text in one exhaustive `switch`,
/// so adding an error here makes the compiler point at the place that needs the new message.
sealed class DomainError {
  const DomainError();
}

/// The entry does not exist (any more): deleted on another device, or a stale link.
final class NotFound extends DomainError {
  const NotFound();
}

/// R6: this user may not do this action (someone else's entry, or the wrong role).
final class NotAllowed extends DomainError {
  const NotAllowed();
}

/// R6: the entry's state does not allow this action (e.g. saving an entry that is still being analysed).
@immutable
final class InvalidTransition extends DomainError {
  const InvalidTransition({required this.from, required this.to});

  final EntryStatus from;
  final EntryStatus to;

  @override
  bool operator ==(Object other) => other is InvalidTransition && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// R2: the user already requested `dailyAnalysisLimit` analyses in the last 24 hours.
/// [availableAt] is when the next one becomes possible ("Sledeća analiza je moguća za 3 h").
@immutable
final class DailyLimitReached extends DomainError {
  const DailyLimitReached({required this.availableAt});

  final DateTime availableAt;

  @override
  bool operator ==(Object other) => other is DailyLimitReached && other.availableAt == availableAt;

  @override
  int get hashCode => availableAt.hashCode;
}

/// R3: the entry is waiting for or going through the analysis, so it cannot be changed or deleted yet.
final class EntryBeingAnalyzed extends DomainError {
  const EntryBeingAnalyzed();
}

/// R1: the text is not a link at all.
final class InvalidLink extends DomainError {
  const InvalidLink();
}

/// R1: the link is not from Instagram or TikTok.
final class UnsupportedPlatform extends DomainError {
  const UnsupportedPlatform();
}

/// R1: an Instagram or TikTok link, but not to a single video (a profile, the home page, ...).
final class NotAVideoLink extends DomainError {
  const NotAVideoLink();
}

/// R8: an editor must say why a proposal is rejected.
final class RejectionReasonEmpty extends DomainError {
  const RejectionReasonEmpty();
}

/// R8: the reason is longer than `RejectionReason.maxLength`; [length] lets the message say by how much.
@immutable
final class RejectionReasonTooLong extends DomainError {
  const RejectionReasonTooLong(this.length);

  final int length;

  @override
  bool operator ==(Object other) => other is RejectionReasonTooLong && other.length == length;

  @override
  int get hashCode => length.hashCode;
}
