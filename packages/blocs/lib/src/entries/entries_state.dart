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
  const EntriesLoaded(this.entries, {this.actions = const {}, this.busyId, this.notice});

  final List<Entry> entries;

  /// The buttons each card shows, as the domain allows them. The screen draws exactly these.
  final Map<EntryId, Set<EntryAction>> actions;

  /// The entry whose action is running; the screen disables its buttons.
  final EntryId? busyId;

  /// A one-time message for a SnackBar, shown once and then acknowledged.
  final EntriesNotice? notice;

  bool get isBusy => busyId != null;

  Set<EntryAction> actionsFor(EntryId id) => actions[id] ?? const {};

  /// The same list while the action on [id] runs.
  EntriesLoaded busyWith(EntryId id) => EntriesLoaded(entries, actions: actions, busyId: id);

  /// The same list, no longer busy, with a message about the last action.
  EntriesLoaded withNotice(EntriesNotice notice) => EntriesLoaded(entries, actions: actions, notice: notice);

  /// The same list after the screen has shown the message.
  EntriesLoaded withoutNotice() => EntriesLoaded(entries, actions: actions, busyId: busyId);

  @override
  List<Object?> get props => [entries, actions, busyId, notice];

  @override
  String toString() =>
      'EntriesLoaded(${entries.length} entries${isBusy ? ', busy ${busyId!.value}' : ''}'
      '${notice == null ? '' : ', $notice'})';
}

/// How an action ended, for one SnackBar.
sealed class EntriesNotice extends Equatable {
  const EntriesNotice(this.action);

  final EntryAction action;
}

/// "Sačuvano", "Predloženo", "Poslato ponovo", "Obrisano".
final class EntryActionSucceeded extends EntriesNotice {
  const EntryActionSucceeded(super.action, this.entry);

  final Entry entry;

  @override
  List<Object?> get props => [action, entry];
}

/// A rule said no; the screen shows `domainErrorText(error)`.
final class EntryActionRejected extends EntriesNotice {
  const EntryActionRejected(super.action, this.error);

  final DomainError error;

  @override
  List<Object?> get props => [action, error];
}

/// The data could not be reached; the screen offers "Pokušaj ponovo", which sends the same action for [id].
final class EntryActionFailed extends EntriesNotice {
  const EntryActionFailed(super.action, this.id, this.cause);

  final EntryId id;
  final Object cause;

  @override
  List<Object?> get props => [action, id, cause];
}
