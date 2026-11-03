import '../errors.dart';
import '../result.dart';
import '../user.dart';
import 'access_policy.dart';
import 'entry.dart';

/// "Obriši": may the owner delete this entry now?
///
/// Success means yes and carries the entry; the use case then removes it through the repository. Deleting a
/// published entry removes it from the user's library only: the catalog record stays.
Result<Entry> deleteEntry(Entry entry, {required User by}) {
  if (!AccessPolicy.canManage(by, entry)) return const Failure(NotAllowed());
  if (entry.status.isBeingAnalyzed) return const Failure(EntryBeingAnalyzed()); // R3
  return Success(entry);
}
