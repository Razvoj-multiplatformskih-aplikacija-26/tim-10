part of 'entries_bloc.dart';

sealed class EntriesEvent {
  const EntriesEvent();
}

/// The library was opened, or the user tapped "Pokušaj ponovo": both load the entries the same way.
final class EntriesRequested extends EntriesEvent {
  const EntriesRequested();
}
