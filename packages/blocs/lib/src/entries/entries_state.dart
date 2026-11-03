part of 'entries_bloc.dart';

/// The four states of the main screen (KT1): loading, failure with "Pokušaj ponovo", empty, data.
sealed class EntriesState extends Equatable {
  const EntriesState();
}

/// The screen shows skeleton cards.
final class EntriesLoading extends EntriesState {
  const EntriesLoading();

  @override
  List<Object?> get props => [];
}

/// The entries could not be loaded (no network, a simulated failure); the screen offers "Pokušaj ponovo".
final class EntriesFailure extends EntriesState {
  const EntriesFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}

/// The user has no entries yet; the screen invites them to add the first video.
final class EntriesEmpty extends EntriesState {
  const EntriesEmpty();

  @override
  List<Object?> get props => [];
}

final class EntriesLoaded extends EntriesState {
  const EntriesLoaded(this.entries);

  final List<Entry> entries;

  @override
  List<Object?> get props => [entries];

  @override
  String toString() => 'EntriesLoaded(${entries.length} entries)';
}
