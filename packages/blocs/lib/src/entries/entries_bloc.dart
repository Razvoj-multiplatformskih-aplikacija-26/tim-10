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
  }) : super(const EntriesLoading()) {
    on<EntriesRequested>(_onRequested);
    on<EntryActionRequested>(_onActionRequested);
    on<EntriesNoticeAcknowledged>(_onNoticeAcknowledged);
  }

  final LoadMyEntries loadMyEntries;
  final SaveEntry save;
  final ProposeEntry propose;
  final RetryAnalysis retry;
  final DeleteEntry delete;

  /// The signed-in user. In KT1 a fixed demo user; from KT2 the one who logged in.
  final User user;

  /// Every load gets a number; an answer to an older load is dropped (a slow first load must not overwrite
  /// the result of "Pokušaj ponovo").
  int _request = 0;

  Future<void> _onRequested(EntriesRequested event, Emitter<EntriesState> emit) async {
    final request = ++_request;
    emit(const EntriesLoading());
    try {
      final entries = await loadMyEntries(user);
      if (request != _request) return;
      emit(entries.isEmpty ? const EntriesEmpty() : EntriesLoaded(entries));
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
    emit(EntriesLoaded(current.entries, busyId: event.id));

    try {
      final result = await _run(event.action, event.id);
      switch (result) {
        case Failure(:final error):
          emit(EntriesLoaded(current.entries, notice: EntryActionRejected(event.action, error)));
        case Success(:final value):
          final entries = await loadMyEntries(user);
          emit(EntriesLoaded(entries, notice: EntryActionSucceeded(event.action, value)));
      }
    } on Exception catch (cause) {
      emit(EntriesLoaded(current.entries, notice: EntryActionFailed(event.action, event.id, cause)));
    }
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
      emit(EntriesLoaded(current.entries, busyId: current.busyId));
    }
  }
}
