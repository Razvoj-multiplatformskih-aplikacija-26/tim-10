import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  group('Clock', () {
    test('the system clock gives the current time in UTC', () {
      final before = DateTime.now().toUtc();
      final now = const SystemClock().now();

      expect(now.isUtc, isTrue);
      expect(now.isBefore(before), isFalse);
    });

    test('a fixed clock always gives the same instant, in UTC', () {
      final clock = FixedClock(DateTime.utc(2026, 11, 4, 18));

      expect(clock.now(), DateTime.utc(2026, 11, 4, 18));
      expect(clock.now(), clock.now());
    });

    test('a fixed clock turns a local time into UTC', () {
      final local = DateTime(2026, 11, 4, 18);

      expect(FixedClock(local).now(), local.toUtc());
      expect(FixedClock(local).now().isUtc, isTrue);
    });
  });

  group('RepositoryException', () {
    test('says what failed and why', () {
      expect(const RepositoryException('entries not loaded').toString(), contains('entries not loaded'));
      expect(const RepositoryException('not saved', 'timeout').toString(), contains('timeout'));
    });
  });
}
