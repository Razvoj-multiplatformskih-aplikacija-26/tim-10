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
final class ReviewQueueEmpty extends ReviewQueueState {
  const ReviewQueueEmpty();

  @override
  List<Object?> get props => [];
}

final class ReviewQueueLoaded extends ReviewQueueState {
  const ReviewQueueLoaded(this.items, {this.canDecide = false, this.cursor = 0, this.isPanelOpen = false});

  /// The proposals, oldest first.
  final List<ReviewItem> items;

  /// Whether the signed-in user may publish and reject. The domain answers; the screen only draws it.
  final bool canDecide;

  /// The index of the row the keyboard is on. Always a valid index, because this state always has rows.
  final int cursor;

  /// Whether the detail of the row under the cursor is shown.
  final bool isPanelOpen;

  /// The proposal under the cursor. "Objavi" and "Odbij" act on this one.
  ReviewItem get current => items[cursor];

  /// The proposal in the panel, or `null` when the panel is closed. This is what the address shows.
  EntryId? get selectedId => isPanelOpen ? current.id : null;

  /// The same queue with the cursor on [index]; past the first or the last row it stays there.
  ReviewQueueLoaded withCursor(int index) => ReviewQueueLoaded(
    items,
    canDecide: canDecide,
    cursor: index.clamp(0, items.length - 1),
    isPanelOpen: isPanelOpen,
  );

  ReviewQueueLoaded withPanel({required bool isOpen}) =>
      ReviewQueueLoaded(items, canDecide: canDecide, cursor: cursor, isPanelOpen: isOpen);

  @override
  List<Object?> get props => [items, canDecide, cursor, isPanelOpen];

  @override
  String toString() => 'ReviewQueueLoaded(${items.length} items, cursor $cursor${isPanelOpen ? ', panel open' : ''})';
}
