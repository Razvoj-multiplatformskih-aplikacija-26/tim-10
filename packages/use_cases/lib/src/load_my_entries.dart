import 'package:domain/domain.dart';

import 'ports/entry_repository.dart';

/// The user's library: all of their own entries, never anyone else's.
final class LoadMyEntries {
  const LoadMyEntries({required this.entries});

  final EntryRepository entries;

  Future<List<Entry>> call(User user) => entries.entriesOf(user.id);
}
