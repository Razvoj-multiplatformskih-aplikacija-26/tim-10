import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('R8 · RejectionReason', () {
    test('rejects an empty reason', () {
      expect(RejectionReason.parse(''), const Failure<RejectionReason>(RejectionReasonEmpty()));
    });

    test('rejects a reason of only spaces', () {
      expect(RejectionReason.parse('   \n '), const Failure<RejectionReason>(RejectionReasonEmpty()));
    });

    test('accepts a reason of exactly 300 characters', () {
      expect(RejectionReason.parse('đ' * 300).valueOrNull?.text, 'đ' * 300);
    });

    test('rejects a reason of 301 characters', () {
      expect(RejectionReason.parse('đ' * 301), const Failure<RejectionReason>(RejectionReasonTooLong(301)));
    });

    test('counts an emoji as one character, as people do', () {
      // '🍜' is two UTF-16 code units, so a plain String.length would say 600.
      expect(RejectionReason.parse('🍜' * 300).isSuccess, isTrue);
    });

    test('trims spaces around the reason', () {
      expect(
        RejectionReason.parse('  Duplikat postojećeg restorana.  ').valueOrNull?.text,
        'Duplikat postojećeg restorana.',
      );
    });

    test('the limit is 300', () {
      expect(RejectionReason.maxLength, 300);
    });
  });
}
