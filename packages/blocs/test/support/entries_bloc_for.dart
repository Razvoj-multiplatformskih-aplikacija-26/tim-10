import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

/// An [EntriesBloc] with every use case over the same [repository], as `dependencies.dart` builds it in the app.
EntriesBloc entriesBlocFor(EntryRepository repository, {required User user, required Clock clock}) => EntriesBloc(
  loadMyEntries: LoadMyEntries(entries: repository),
  save: SaveEntry(entries: repository, clock: clock),
  propose: ProposeEntry(entries: repository, clock: clock),
  retry: RetryAnalysis(entries: repository, clock: clock),
  delete: DeleteEntry(entries: repository),
  user: user,
);
