import '../entry/entry.dart';
import '../errors.dart';
import '../result.dart';

/// R2 (README): at most 20 analyses a day per user. The form reads this constant too.
const dailyAnalysisLimit = 20;

/// "A day" is the last 24 hours, not a calendar day: no time zones and no midnight.
const analysisWindow = Duration(hours: 24);

/// How many analyses the user may still start now, for "Preostalo analiza danas: N".
int remainingAnalyses(List<Entry> mine, {required DateTime now}) {
  final used = _requestsInWindow(mine, now: now).length;
  return used >= dailyAnalysisLimit ? 0 : dailyAnalysisLimit - used;
}

/// R2 as a rule: the number of analyses left, or [DailyLimitReached] with the time the next one becomes possible.
///
/// A rule over the user's own entries. The client uses it for an instant answer; the server decides (KT2).
Result<int> checkDailyLimit(List<Entry> mine, {required DateTime now}) {
  final requests = _requestsInWindow(mine, now: now);
  if (requests.length < dailyAnalysisLimit) return Success(dailyAnalysisLimit - requests.length);

  // Requests leave the window oldest first. With exactly 20 in it, the oldest one frees the next place.
  final freesPlace = requests[requests.length - dailyAnalysisLimit];
  return Failure(DailyLimitReached(availableAt: freesPlace.add(analysisWindow)));
}

/// Every analysis request of the user in the last 24 hours, oldest first. A request exactly 24 hours old is out.
List<DateTime> _requestsInWindow(List<Entry> mine, {required DateTime now}) {
  final since = now.toUtc().subtract(analysisWindow);
  return [
    for (final entry in mine)
      for (final at in entry.analysisRequests)
        if (at.isAfter(since)) at,
  ]..sort();
}
