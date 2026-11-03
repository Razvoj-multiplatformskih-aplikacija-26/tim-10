import 'package:domain/domain.dart';

import 'ports/entry_repository.dart';

/// "Obriši": find the entry, let the domain decide (`deleteEntry`: the owner, and R3), then remove it.
///
/// Returns the deleted entry, so the screen can say what was deleted.
final class DeleteEntry {
  const DeleteEntry({required this.entries});

  final EntryRepository entries;

  Future<Result<Entry>> call(EntryId id, {required User by}) async {
    final entry = await entries.find(id);
    if (entry == null) return const Failure(NotFound());
    if (deleteEntry(entry, by: by) case Failure(:final error)) return Failure(error);

    await entries.delete(entry.id);
    return Success(entry);
  }
}
