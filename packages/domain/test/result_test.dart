import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('a success carries its value and no error', () {
      const Result<int> result = Success(20);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 20);
      expect(result.errorOrNull, isNull);
    });

    test('a failure carries its error and no value', () {
      const Result<int> result = Failure(InvalidLink());

      expect(result.isSuccess, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, const InvalidLink());
    });

    test('successes are equal when their values are equal', () {
      expect(Success<int>(20), Success<int>(20));
      expect(Success<int>(20), isNot(Success<int>(21)));
    });

    test('failures are equal when their errors are equal', () {
      expect(Failure<int>(const InvalidLink()), Failure<int>(const InvalidLink()));
      expect(Failure<int>(const InvalidLink()), isNot(Failure<int>(const UnsupportedPlatform())));
    });

    test('a success is never equal to a failure', () {
      expect(Success<int>(20), isNot(Failure<int>(const InvalidLink())));
    });
  });
}
