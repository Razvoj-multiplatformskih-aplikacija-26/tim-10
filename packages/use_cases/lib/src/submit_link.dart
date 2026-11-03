import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/entry_repository.dart';

/// "Dodaj link": the client checks the daily limit at once, the repository (the server in KT2) decides.
///
/// 1. load the user's entries;
/// 2. check R2 here, so a user over the limit gets the answer without sending anything;
/// 3. send the link; the repository checks R2 again over its own data and applies R4.
final class SubmitLink {
  const SubmitLink({required this.entries, required this.clock});

  final EntryRepository entries;
  final Clock clock;

  Future<Result<List<Entry>>> call(VideoLink link, {required User by}) async {
    final mine = await entries.entriesOf(by.id);
    return switch (checkDailyLimit(mine, now: clock.now())) {
      Failure(:final error) => Failure(error),
      Success() => await entries.submitLink(link, owner: by.id),
    };
  }
}
