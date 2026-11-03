import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

/// R8: why an editor rejected a proposal. The user sees it next to the "Odbijeno" badge.
///
/// The constructor is private, so an empty or too long reason cannot exist: the backoffice dialog, the Bloc and
/// the server (KT2) all go through [parse].
@immutable
final class RejectionReason {
  const RejectionReason._(this.text);

  /// The limit is a named constant, so the dialog's character counter reads the same number.
  static const maxLength = 300;

  final String text;

  static Result<RejectionReason> parse(String input) {
    final text = input.trim();
    if (text.isEmpty) return const Failure(RejectionReasonEmpty());
    final length = text.characters.length; // letters as people count them, not UTF-16 code units
    if (length > maxLength) return Failure(RejectionReasonTooLong(length));
    return Success(RejectionReason._(text));
  }

  @override
  bool operator ==(Object other) => other is RejectionReason && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'RejectionReason($text)';
}
