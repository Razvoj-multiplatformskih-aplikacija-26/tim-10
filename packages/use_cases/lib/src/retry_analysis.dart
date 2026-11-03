import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/entry_repository.dart';

/// "Pokušaj ponovo": a failed link goes back to the analysis, and that counts toward the daily limit (R2).
///
/// The domain answers first (who may do it, and whether the entry failed at all), so a user who taps "retry" on the
/// wrong entry is told that, not that the limit is reached. Then the limit, then the store. In KT1 the fake
/// repository sees the entry back in `Queued` and starts the analysis again, as the server will.
final class RetryAnalysis {
  const RetryAnalysis({required this.entries, required this.clock});

  final EntryRepository entries;
  final Clock clock;

  Future<Result<Entry>> call(EntryId id, {required User by}) async {
    final entry = await entries.find(id);
    if (entry == null) return const Failure(NotFound());

    final now = clock.now();
    final retried = retryAnalysis(entry, by: by, now: now);
    if (retried case Failure(:final error)) return Failure(error);

    final mine = await entries.entriesOf(by.id);
    if (checkDailyLimit(mine, now: now) case Failure(:final error)) return Failure(error);

    return Success(await entries.save(retried.valueOrNull!));
  }
}
