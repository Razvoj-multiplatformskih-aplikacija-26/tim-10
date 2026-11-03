part of 'review_queue_bloc.dart';

sealed class ReviewQueueEvent {
  const ReviewQueueEvent();
}

/// The queue was opened, or the editor tapped "Pokušaj ponovo": both load the proposals the same way.
///
/// [selected] comes from the address (`/queue?entry=e-12`): that proposal opens in the panel once the list is here.
final class ReviewQueueRequested extends ReviewQueueEvent {
  const ReviewQueueRequested({this.selected});

  final EntryId? selected;
}

/// An arrow key: one row down (1) or up (-1).
final class ReviewCursorMoved extends ReviewQueueEvent {
  const ReviewCursorMoved(this.delta);

  final int delta;
}

/// Enter: open the row under the cursor in the panel.
final class ReviewCursorActivated extends ReviewQueueEvent {
  const ReviewCursorActivated();
}

/// A click on a row, or a change of the address.
final class ReviewItemOpened extends ReviewQueueEvent {
  const ReviewItemOpened(this.id);

  final EntryId id;
}

/// Esc, or the "X" in the panel.
final class ReviewPanelClosed extends ReviewQueueEvent {
  const ReviewPanelClosed();
}
