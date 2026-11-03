part of 'review_queue_bloc.dart';

/// The four states of the main screen (KT1): loading, failure with "Pokušaj ponovo", empty, data.
sealed class ReviewQueueState extends Equatable {
  const ReviewQueueState();
}

/// The screen shows empty rows.
final class ReviewQueueLoading extends ReviewQueueState {
  const ReviewQueueLoading();

  @override
  List<Object?> get props => [];
}

/// The proposals could not be loaded; the screen offers "Pokušaj ponovo".
final class ReviewQueueFailure extends ReviewQueueState {
  const ReviewQueueFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}

/// Nothing is waiting for a decision.
///
/// It carries a [notice] because deciding on the last proposal ends here, and that decision still needs its SnackBar.
final class ReviewQueueEmpty extends ReviewQueueState {
  const ReviewQueueEmpty({this.notice});

  final ReviewNotice? notice;

  @override
  List<Object?> get props => [notice];
}

final class ReviewQueueLoaded extends ReviewQueueState {
  const ReviewQueueLoaded(
    this.items, {
    this.canDecide = false,
    this.cursor = 0,
    this.isPanelOpen = false,
    this.busyId,
    this.notice,
  });

  /// The proposals, oldest first.
  final List<ReviewItem> items;

  /// Whether the signed-in user may publish and reject. The domain answers; the screen only draws it.
  final bool canDecide;

  /// The index of the row the keyboard is on. Always a valid index, because this state always has rows.
  final int cursor;

  /// Whether the detail of the row under the cursor is shown.
  final bool isPanelOpen;

  /// The proposal whose decision is running; the screen disables the buttons and shows a progress bar.
  final EntryId? busyId;

  /// A one-time message for a SnackBar, shown once and then acknowledged.
  final ReviewNotice? notice;

  bool get isBusy => busyId != null;

  /// The proposal under the cursor. "Objavi" and "Odbij" act on this one.
  ReviewItem get current => items[cursor];

  /// The proposal in the panel, or `null` when the panel is closed. This is what the address shows.
  EntryId? get selectedId => isPanelOpen ? current.id : null;

  /// The same queue with the cursor on [index]; past the first or the last row it stays there.
  ReviewQueueLoaded withCursor(int index) =>
      _copy(cursor: index.clamp(0, items.length - 1), busyId: busyId, notice: notice);

  ReviewQueueLoaded withPanel({required bool isOpen}) => _copy(isPanelOpen: isOpen, busyId: busyId, notice: notice);

  /// The same queue while the decision on [id] runs.
  ReviewQueueLoaded busyWith(EntryId id) => _copy(busyId: id);

  /// The same queue, no longer busy, with a message about the last decision.
  ReviewQueueLoaded withNotice(ReviewNotice notice) => _copy(notice: notice);

  /// The same queue after the screen has shown the message.
  ReviewQueueLoaded withoutNotice() => _copy(busyId: busyId);

  ReviewQueueLoaded _copy({int? cursor, bool? isPanelOpen, EntryId? busyId, ReviewNotice? notice}) => ReviewQueueLoaded(
    items,
    canDecide: canDecide,
    cursor: cursor ?? this.cursor,
    isPanelOpen: isPanelOpen ?? this.isPanelOpen,
    busyId: busyId,
    notice: notice,
  );

  @override
  List<Object?> get props => [items, canDecide, cursor, isPanelOpen, busyId, notice];

  @override
  String toString() => 'ReviewQueueLoaded(${items.length} items, cursor $cursor${isPanelOpen ? ', panel open' : ''})';
}

/// How a decision ended, for one SnackBar.
sealed class ReviewNotice extends Equatable {
  const ReviewNotice();
}

/// "Objavljeno u katalogu" or "Predlog je odbijen".
final class ReviewActionSucceeded extends ReviewNotice {
  const ReviewActionSucceeded(this.decision);

  final ReviewDecision decision;

  @override
  List<Object?> get props => [decision];
}

/// A rule said no; the screen shows `domainErrorText(error)`.
final class ReviewActionRefused extends ReviewNotice {
  const ReviewActionRefused(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

/// The data could not be reached. "Pokušaj ponovo" in the SnackBar sends the same [request] again.
final class ReviewActionFailed extends ReviewNotice {
  const ReviewActionFailed(this.request, this.cause);

  final ReviewQueueEvent request;
  final Object cause;

  @override
  List<Object?> get props => [request, cause];
}
