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
  const EntriesEmpty({this.notice});

  /// A one-time message: deleting the last entry ends here, and it still has to say so.
  final EntriesNotice? notice;

  @override
  List<Object?> get props => [notice];
}

final class EntriesLoaded extends EntriesState {
  const EntriesLoaded(
    this.entries, {
    this.actions = const {},
    this.kind = KindFilter.all,
    this.status,
    this.busyId,
    this.notice,
  });

  /// All of the user's entries; the screen draws [visible].
  final List<Entry> entries;

  /// The buttons each card shows, as the domain allows them. The screen draws exactly these.
  final Map<EntryId, Set<EntryAction>> actions;

  /// The segment: Sve / Recepti / Restorani.
  final KindFilter kind;

  /// The selected status chip, or `null` for all.
  final StatusFilter? status;

  /// The entry whose action is running; the screen disables its buttons.
  final EntryId? busyId;

  /// A one-time message for a SnackBar, shown once and then acknowledged.
  final EntriesNotice? notice;

  bool get isBusy => busyId != null;

  Set<EntryAction> actionsFor(EntryId id) => actions[id] ?? const {};

  /// The entries after both filters.
  List<Entry> get visible => [
    for (final entry in entries)
      if (_matchesKind(entry, kind) && (status == null || statusFilterOf(entry.status) == status)) entry,
  ];

  /// The number on a status chip, within the selected segment.
  int countFor(StatusFilter chip) =>
      entries.where((entry) => _matchesKind(entry, kind) && statusFilterOf(entry.status) == chip).length;

  /// For the banner "2 videa čekaju pregled".
  int get forReviewCount => countFor(StatusFilter.forReview);

  /// The same list while the action on [id] runs.
  EntriesLoaded busyWith(EntryId id) =>
      EntriesLoaded(entries, actions: actions, kind: kind, status: status, busyId: id);

  /// The same list, no longer busy, with a message about the last action.
  EntriesLoaded withNotice(EntriesNotice notice) =>
      EntriesLoaded(entries, actions: actions, kind: kind, status: status, notice: notice);

  /// The same list after the screen has shown the message.
  EntriesLoaded withoutNotice() => EntriesLoaded(entries, actions: actions, kind: kind, status: status, busyId: busyId);

  /// The same list seen through other filters.
  EntriesLoaded withFilters({required KindFilter kind, required StatusFilter? status}) =>
      EntriesLoaded(entries, actions: actions, kind: kind, status: status, busyId: busyId, notice: notice);

  @override
  List<Object?> get props => [entries, actions, kind, status, busyId, notice];

  @override
  String toString() =>
      'EntriesLoaded(${entries.length} entries${isBusy ? ', busy ${busyId!.value}' : ''}'
      '${notice == null ? '' : ', $notice'})';
}

/// The segment of the library (M-03). Collections are a separate view, after KT1.
enum KindFilter { all, recipes, restaurants }

/// The status chips of the library (M-03): five chips for eight states.
enum StatusFilter { forReview, processing, saved, catalog, rejected }

/// Which chip a state belongs to. A failed analysis is "U obradi", because it still waits for "Pokušaj ponovo";
/// a proposal waiting for the editor is "U katalogu", on its way there.
StatusFilter statusFilterOf(EntryStatus status) => switch (status) {
  AwaitingReview() => StatusFilter.forReview,
  Queued() || Analyzing() || AnalysisFailed() => StatusFilter.processing,
  Saved() => StatusFilter.saved,
  PendingApproval() || Published() => StatusFilter.catalog,
  Rejected() => StatusFilter.rejected,
};

/// An entry without content yet (waiting or failed) has no kind, so it shows only under "Sve".
bool _matchesKind(Entry entry, KindFilter kind) => switch (kind) {
  KindFilter.all => true,
  KindFilter.recipes => entry.content is RecipeContent,
  KindFilter.restaurants => entry.content is RestaurantContent,
};

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
