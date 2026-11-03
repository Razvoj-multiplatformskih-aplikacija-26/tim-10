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

/// What an editor can decide about a proposal; each is one button, one shortcut and one transition.
enum ReviewDecision { publish, reject }

/// "Objavi" or the O key.
final class ProposalPublishRequested extends ReviewQueueEvent {
  const ProposalPublishRequested(this.id);

  final EntryId id;
}

/// "Odbij" in the dialog, with a reason that has passed `RejectionReason.parse` (R8).
final class ProposalRejectRequested extends ReviewQueueEvent {
  const ProposalRejectRequested(this.id, this.reason);

  final EntryId id;
  final RejectionReason reason;
}

/// The screen has shown the notice (a SnackBar); the Bloc can forget it.
final class ReviewNoticeAcknowledged extends ReviewQueueEvent {
  const ReviewNoticeAcknowledged();
}
