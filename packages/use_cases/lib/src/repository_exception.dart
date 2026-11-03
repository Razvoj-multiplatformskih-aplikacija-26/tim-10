/// The data could not be loaded or saved: no network, a server error, a simulated failure in the fake repository.
///
/// Thrown, not returned. A broken rule is a `Failure(DomainError)`; this is infrastructure, and the screen shows it
/// as "Nije sačuvano" with "Pokušaj ponovo". [message] is for developers, never shown to the user.
final class RepositoryException implements Exception {
  const RepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null ? 'RepositoryException: $message' : 'RepositoryException: $message ($cause)';
}
