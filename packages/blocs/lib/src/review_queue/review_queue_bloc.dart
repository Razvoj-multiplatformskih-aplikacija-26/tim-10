import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'review_queue_event.dart';
part 'review_queue_state.dart';

/// The editor's queue: loads the proposals, shows one of four states, keeps the cursor and the open panel, and runs
/// the two decisions.
///
/// The cursor and the panel live here, not in a widget: narrowing the window replaces the table with a list, Flutter
/// throws away the table's `State`, and the selection must survive that.
final class ReviewQueueBloc extends Bloc<ReviewQueueEvent, ReviewQueueState> {
  ReviewQueueBloc({required this.loadQueue, required this.publish, required this.reject, required this.editor})
    : super(const ReviewQueueLoading()) {
    on<ReviewQueueRequested>(_onRequested);
    on<ReviewCursorMoved>(_onCursorMoved);
    on<ReviewCursorActivated>(_onCursorActivated);
    on<ReviewItemOpened>(_onItemOpened);
    on<ReviewPanelClosed>(_onPanelClosed);
    on<ProposalPublishRequested>(_onPublishRequested);
    on<ProposalRejectRequested>(_onRejectRequested);
    on<ReviewNoticeAcknowledged>(_onNoticeAcknowledged);
  }

  final LoadReviewQueue loadQueue;
  final PublishProposal publish;
  final RejectProposal reject;

  /// The signed-in editor. In KT1 a fixed demo user; from KT2 the one who logged in.
  final User editor;

  /// Every load gets a number; an answer to an older load is dropped.
  int _request = 0;

  Future<void> _onRequested(ReviewQueueRequested event, Emitter<ReviewQueueState> emit) async {
    final request = ++_request;
    emit(const ReviewQueueLoading());
    try {
      final items = await loadQueue();
      if (request != _request) return;
      emit(items.isEmpty ? const ReviewQueueEmpty() : _opened(_loaded(items), event.selected));
    } on Exception catch (cause) {
      if (request != _request) return;
      emit(ReviewQueueFailure(cause));
    }
  }

  /// The panel follows the cursor: with the panel open, the arrows show the next proposal.
  void _onCursorMoved(ReviewCursorMoved event, Emitter<ReviewQueueState> emit) {
    final current = state;
    if (current is ReviewQueueLoaded) emit(current.withCursor(current.cursor + event.delta));
  }

  void _onCursorActivated(ReviewCursorActivated event, Emitter<ReviewQueueState> emit) {
    final current = state;
    if (current is ReviewQueueLoaded) emit(current.withPanel(isOpen: true));
  }

  void _onItemOpened(ReviewItemOpened event, Emitter<ReviewQueueState> emit) {
    final current = state;
    if (current is ReviewQueueLoaded) emit(_opened(current, event.id));
  }

  void _onPanelClosed(ReviewPanelClosed event, Emitter<ReviewQueueState> emit) {
    final current = state;
    if (current is ReviewQueueLoaded) emit(current.withPanel(isOpen: false));
  }

  Future<void> _onPublishRequested(ProposalPublishRequested event, Emitter<ReviewQueueState> emit) =>
      _decide(event, event.id, ReviewDecision.publish, emit, () => publish(event.id, by: editor));

  Future<void> _onRejectRequested(ProposalRejectRequested event, Emitter<ReviewQueueState> emit) =>
      _decide(event, event.id, ReviewDecision.reject, emit, () => reject(event.id, by: editor, reason: event.reason));

  /// One decision at a time: while a proposal is busy, another key press is ignored. The rule is in the domain, called
  /// through the use case; the Bloc only turns the outcome into a notice and reloads the queue after a success.
  ///
  /// After a success the cursor stays on the same row, which now holds the next proposal, so an editor can go through
  /// the queue without moving the cursor.
  Future<void> _decide(
    ReviewQueueEvent request,
    EntryId id,
    ReviewDecision decision,
    Emitter<ReviewQueueState> emit,
    Future<Result<Entry>> Function() run,
  ) async {
    final current = state;
    if (current is! ReviewQueueLoaded || current.isBusy) return;
    emit(current.busyWith(id));

    try {
      switch (await run()) {
        case Failure(:final error):
          emit(current.withNotice(ReviewActionRefused(error)));
        case Success():
          final items = await loadQueue();
          final notice = ReviewActionSucceeded(decision);
          emit(
            items.isEmpty
                ? ReviewQueueEmpty(notice: notice)
                : _loaded(items).withCursor(current.cursor).withPanel(isOpen: current.isPanelOpen).withNotice(notice),
          );
      }
    } on Exception catch (cause) {
      emit(current.withNotice(ReviewActionFailed(request, cause)));
    }
  }

  void _onNoticeAcknowledged(ReviewNoticeAcknowledged event, Emitter<ReviewQueueState> emit) {
    switch (state) {
      case final ReviewQueueLoaded current when current.notice != null:
        emit(current.withoutNotice());
      case final ReviewQueueEmpty current when current.notice != null:
        emit(const ReviewQueueEmpty());
      default:
        break;
    }
  }

  /// The same queue with the panel on [id]. An id that is not in the queue (an old link) closes the panel.
  ReviewQueueLoaded _opened(ReviewQueueLoaded queue, EntryId? id) {
    final index = queue.items.indexWhere((item) => item.id == id);
    return index < 0 ? queue.withPanel(isOpen: false) : queue.withCursor(index).withPanel(isOpen: true);
  }

  ReviewQueueLoaded _loaded(List<ReviewItem> items) =>
      ReviewQueueLoaded(items, canDecide: AccessPolicy.canDecide(editor));
}
