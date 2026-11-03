import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/entry_repository.dart';

/// "Predloži za katalog": find the entry, let the domain decide (`proposeEntry`), store the result.
final class ProposeEntry {
  const ProposeEntry({required this.entries, required this.clock});

  final EntryRepository entries;
  final Clock clock;

  Future<Result<Entry>> call(EntryId id, {required User by}) async {
    final entry = await entries.find(id);
    if (entry == null) return const Failure(NotFound());
    return switch (proposeEntry(entry, by: by, now: clock.now())) {
      Failure(:final error) => Failure(error),
      Success(:final value) => Success(await entries.save(value)),
    };
  }
}
