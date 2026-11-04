import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'entries_event.dart';
part 'entries_state.dart';

/// The user's library (M-03): loads their entries, shows one of four states and runs the owner's actions.
final class EntriesBloc extends Bloc<EntriesEvent, EntriesState> {
  EntriesBloc({
    required this.loadMyEntries,
    required this.save,
    required this.propose,
    required this.retry,
    required this.delete,
    required this.user,
    required this.clock,
  }) : super(const EntriesLoading()) {
    on<EntriesRequested>(_onRequested);
    on<EntryActionRequested>(_onActionRequested);
    on<EntriesKindFilterChanged>(_onKindFilterChanged);
    on<EntriesStatusFilterToggled>(_onStatusFilterToggled);
    on<EntriesNoticeAcknowledged>(_onNoticeAcknowledged);
  }

  final LoadMyEntries loadMyEntries;
  final SaveEntry save;
  final ProposeEntry propose;
  final RetryAnalysis retry;
  final DeleteEntry delete;

  /// The signed-in user. In KT1 a fixed demo user; from KT2 the one who logged in.
  final User user;

  final Clock clock;

  /// Every load gets a number; an answer to an older load is dropped (a slow first load must not overwrite
  /// the result of "Pokušaj ponovo").
  int _request = 0;

  /// The filters to put back after a load. Loading and failure carry no list, so they cannot hold them.
  KindFilter _kind = KindFilter.all;
  StatusFilter? _status;

  void _rememberFilters({required bool showAll}) {
    final current = state;
    if (showAll) {
      _kind = KindFilter.all;
      _status = null;
    } else if (current is EntriesLoaded) {
      _kind = current.kind;
      _status = current.status;
    }
  }

  Future<void> _onRequested(EntriesRequested event, Emitter<EntriesState> emit) async {
    final request = ++_request;
    _rememberFilters(showAll: event.showAll);
    emit(const EntriesLoading());
    try {
      final entries = await loadMyEntries(user);
      if (request != _request) return;
      emit(_listOf(entries, kind: _kind, status: _status));
    } on Exception catch (cause) {
      if (request != _request) return;
      emit(EntriesFailure(cause));
    }
  }

  /// One action at a time: while an entry is busy, another tap is ignored. The rule is in the domain, called
  /// through the use case; the Bloc only turns the outcome into a notice and reloads the list after a success,
  /// without the skeleton.
  Future<void> _onActionRequested(EntryActionRequested event, Emitter<EntriesState> emit) async {
    final current = state;
    if (current is! EntriesLoaded || current.isBusy) return;
    emit(current.busyWith(event.id));

    try {
      final result = await _run(event.action, event.id);
      switch (result) {
        case Failure(:final error):
          emit(current.withNotice(EntryActionRejected(event.action, error)));
        case Success(:final value):
          final entries = await loadMyEntries(user);
          emit(
            _listOf(
              entries,
              kind: current.kind,
              status: current.status,
              notice: EntryActionSucceeded(event.action, value),
            ),
          );
      }
    } on Exception catch (cause) {
      emit(current.withNotice(EntryActionFailed(event.action, event.id, cause)));
    }
  }

  void _onKindFilterChanged(EntriesKindFilterChanged event, Emitter<EntriesState> emit) {
    final current = state;
    if (current is EntriesLoaded) emit(current.withFilters(kind: event.kind, status: current.status));
  }

  void _onStatusFilterToggled(EntriesStatusFilterToggled event, Emitter<EntriesState> emit) {
    final current = state;
    if (current is! EntriesLoaded) return;
    final status = current.status == event.chip ? null : event.chip;
    emit(current.withFilters(kind: current.kind, status: status));
  }

  /// A fresh list keeps the filters the user picked. The empty state shows no filters, so it also forgets them:
  /// one the user cannot see must not hide their first new entry.
  EntriesState _listOf(
    List<Entry> entries, {
    required KindFilter kind,
    required StatusFilter? status,
    EntriesNotice? notice,
  }) {
    if (entries.isEmpty) {
      _kind = KindFilter.all;
      _status = null;
      return EntriesEmpty(notice: notice);
    }
    return EntriesLoaded(entries, actions: _allowedActions(entries), kind: kind, status: status, notice: notice);
  }

  /// Which buttons each card shows. The domain answers by trying each action; the screen decides nothing.
  /// A retry over the daily limit still shows the button: the limit is checked when it is tapped (R2).
  Map<EntryId, Set<EntryAction>> _allowedActions(List<Entry> entries) {
    final now = clock.now();
    return {
      for (final entry in entries)
        entry.id: {
          if (saveEntry(entry, by: user, now: now).isSuccess) EntryAction.save,
          if (proposeEntry(entry, by: user, now: now).isSuccess) EntryAction.propose,
          if (retryAnalysis(entry, by: user, now: now).isSuccess) EntryAction.retry,
          if (deleteEntry(entry, by: user).isSuccess) EntryAction.delete,
        },
    };
  }

  Future<Result<Entry>> _run(EntryAction action, EntryId id) => switch (action) {
    EntryAction.save => save(id, by: user),
    EntryAction.propose => propose(id, by: user),
    EntryAction.retry => retry(id, by: user),
    EntryAction.delete => delete(id, by: user),
  };

  void _onNoticeAcknowledged(EntriesNoticeAcknowledged event, Emitter<EntriesState> emit) {
    final current = state;
    if (current is EntriesLoaded && current.notice != null) {
      emit(current.withoutNotice());
    } else if (current is EntriesEmpty && current.notice != null) {
      emit(const EntriesEmpty());
    }
  }
}
