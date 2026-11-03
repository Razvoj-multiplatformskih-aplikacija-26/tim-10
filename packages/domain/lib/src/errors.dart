import 'package:meta/meta.dart';

/// Every way a domain rule can fail.
///
/// An error is a type, never a message: the apps turn each error into Serbian text in one exhaustive `switch`,
/// so adding an error here makes the compiler point at the place that needs the new message.
sealed class DomainError {
  const DomainError();
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
