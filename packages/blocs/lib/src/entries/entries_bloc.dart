import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'entries_event.dart';
part 'entries_state.dart';

/// The user's library (M-03): loads their entries and shows one of four states.
final class EntriesBloc extends Bloc<EntriesEvent, EntriesState> {
  EntriesBloc({required this.loadMyEntries, required this.user}) : super(const EntriesLoading()) {
    on<EntriesRequested>(_onRequested);
  }

  final LoadMyEntries loadMyEntries;

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
}
