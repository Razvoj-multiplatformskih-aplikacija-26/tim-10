import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 18);
  var nextId = 0;

  Entry entryWith(List<DateTime> analysisRequests) => Entry(
    id: EntryId('e-${nextId++}'),
    owner: const UserId('u-petar'),
    source: const Manual(),
    status: Saved(at: now),
    createdAt: now,
    analysisRequests: analysisRequests,
  );

  /// [count] entries, one request each, one minute apart, the newest a minute ago.
  List<Entry> recentEntries(int count) => [
    for (var i = 0; i < count; i++) entryWith([now.subtract(Duration(minutes: count - i))]),
  ];

  group('R2 · daily limit', () {
    test('a user with no requests has all 20 analyses', () {
      expect(remainingAnalyses(const <Entry>[], now: now), 20);
      expect(checkDailyLimit(const <Entry>[], now: now), const Success(20));
    });

    test('19 requests leave one analysis', () {
      expect(remainingAnalyses(recentEntries(19), now: now), 1);
      expect(checkDailyLimit(recentEntries(19), now: now), const Success(1));
    });

    test('20 requests reach the limit', () {
      expect(remainingAnalyses(recentEntries(20), now: now), 0);
      expect(checkDailyLimit(recentEntries(20), now: now).errorOrNull, isA<DailyLimitReached>());
    });

    test('a request exactly 24 hours old no longer counts', () {
      final mine = [
        ...recentEntries(19),
        entryWith([now.subtract(const Duration(hours: 24))]),
      ];

      expect(remainingAnalyses(mine, now: now), 1);
    });

    test('a request 23 h 59 min old still counts', () {
      final mine = [
        ...recentEntries(19),
        entryWith([now.subtract(const Duration(hours: 23, minutes: 59))]),
      ];

      expect(remainingAnalyses(mine, now: now), 0);
    });

    test('the next analysis is possible 24 hours after the oldest request in the window', () {
      final oldest = now.subtract(const Duration(hours: 21));
      final mine = [
        ...recentEntries(19),
        entryWith([oldest]),
      ];

      expect(
        checkDailyLimit(mine, now: now),
        Failure<int>(DailyLimitReached(availableAt: oldest.add(const Duration(hours: 24)))),
      );
    });

    test('counts the new link and every retry of the same entry', () {
      final retriedTwice = entryWith([
        now.subtract(const Duration(hours: 3)),
        now.subtract(const Duration(hours: 2)),
        now.subtract(const Duration(hours: 1)),
      ]);

      expect(remainingAnalyses([retriedTwice], now: now), 17);
    });

    test('an entry copied from an existing analysis (R4) costs nothing', () {
      expect(remainingAnalyses([...recentEntries(19), entryWith([])], now: now), 1);
    });

    test('never says less than zero', () {
      expect(remainingAnalyses(recentEntries(25), now: now), 0);
    });
  });
}
