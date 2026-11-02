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

/// R1: the text is a link, but not to an Instagram or TikTok video.
final class UnsupportedPlatform extends DomainError {
  const UnsupportedPlatform();
}
