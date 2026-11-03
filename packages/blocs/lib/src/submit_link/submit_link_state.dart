part of 'submit_link_bloc.dart';

/// Everything the form shows. One state with fields, because a form is always "being filled in".
final class SubmitLinkState extends Equatable {
  const SubmitLinkState({
    this.input = '',
    this.link,
    this.linkError,
    this.remaining,
    this.limitError,
    this.isSending = false,
    this.notice,
  });

  /// What is in the field, as typed.
  final String input;

  /// R1 passed: the recognised video (the green block "Video je prepoznat").
  final VideoLink? link;

  /// R1 failed: the screen shows `domainErrorText(linkError)` under the field.
  final DomainError? linkError;

  /// R2: analyses left today, for "Još 17 od 20"; `null` until loaded.
  final int? remaining;

  /// R2 reached: `DailyLimitReached` with the time the next analysis is possible (the mustard block).
  final DomainError? limitError;

  final bool isSending;

  /// The outcome of sending, shown once.
  final SubmitNotice? notice;

  /// "Analiziraj video" is enabled only for a valid link, under the limit, and not while sending.
  bool get canSubmit => link != null && limitError == null && !isSending;

  /// A new text in the field, with the result of R1 (both `null` for an empty field).
  SubmitLinkState withInput(String input, {VideoLink? link, DomainError? linkError}) => SubmitLinkState(
    input: input,
    link: link,
    linkError: linkError,
    remaining: remaining,
    limitError: limitError,
    isSending: isSending,
    notice: notice,
  );

  SubmitLinkState withQuota({required int remaining, DomainError? limitError}) => SubmitLinkState(
    input: input,
    link: link,
    linkError: linkError,
    remaining: remaining,
    limitError: limitError,
    isSending: isSending,
    notice: notice,
  );

  SubmitLinkState sending() => SubmitLinkState(
    input: input,
    link: link,
    linkError: linkError,
    remaining: remaining,
    limitError: limitError,
    isSending: true,
  );

  /// Sending is over (or the message was shown, with `null`); the form keeps what was typed.
  SubmitLinkState withNotice(SubmitNotice? notice) => SubmitLinkState(
    input: input,
    link: link,
    linkError: linkError,
    remaining: remaining,
    limitError: limitError,
    notice: notice,
  );

  @override
  List<Object?> get props => [input, link, linkError, remaining, limitError, isSending, notice];

  @override
  String toString() =>
      'SubmitLinkState(${link ?? linkError?.runtimeType ?? 'empty'}, remaining $remaining'
      '${isSending ? ', sending' : ''}${notice == null ? '' : ', $notice'})';
}

/// How sending ended.
sealed class SubmitNotice extends Equatable {
  const SubmitNotice();
}

/// Sent. The screen closes and says "Analiziramo video…", or, when the video was already analysed (R4),
/// "Ovaj video je već analiziran. Rezultat je odmah tu."
final class SubmitSucceeded extends SubmitNotice {
  const SubmitSucceeded(this.entries);

  final List<Entry> entries;

  /// R4: the result was copied at once, so the entries already wait for the user's review.
  bool get alreadyAnalyzed => entries.isNotEmpty && entries.first.status is AwaitingReview;

  @override
  List<Object?> get props => [entries];
}

/// The repository (the server) said no, e.g. `DailyLimitReached`; the message goes under the button.
final class SubmitRejected extends SubmitNotice {
  const SubmitRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

/// Sending failed (no network); a SnackBar offers "Pokušaj ponovo", and the field keeps the link.
final class SubmitFailed extends SubmitNotice {
  const SubmitFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
