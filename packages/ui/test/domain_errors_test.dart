import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  // Local times, as the phone shows them; the domain keeps UTC.
  final now = DateTime(2026, 11, 4, 14, 5);

  group('domainErrorText', () {
    test('every domain error has a sentence', () {
      final at = now.toUtc();
      final errors = <DomainError>[
        const InvalidLink(),
        const UnsupportedPlatform(),
        const NotAVideoLink(),
        DailyLimitReached(availableAt: at),
        const EntryBeingAnalyzed(),
        const RejectionReasonEmpty(),
        const RejectionReasonTooLong(312),
        const NotAllowed(),
        InvalidTransition(
          from: Queued(at: at),
          to: Saved(at: at),
        ),
        const NotFound(),
      ];

      for (final error in errors) {
        final text = domainErrorText(error, now: now.toUtc());
        expect(text, isNotEmpty);
        // A whole sentence; the InvalidLink example link ends with "…" as in the M-05 nacrt.
        expect(text, matches(RegExp(r'[.…]$')), reason: '$error');
      }
    });

    test('the daily limit says the time of the next analysis, today', () {
      final text = domainErrorText(
        DailyLimitReached(availableAt: DateTime(2026, 11, 4, 23, 40).toUtc()),
        now: now.toUtc(),
      );

      expect(text, 'Iskorišćeno je svih 20 današnjih analiza. Sledeća se oslobađa danas u 23:40.');
    });

    test('the daily limit says "sutra" when the next analysis is tomorrow', () {
      final text = domainErrorText(
        DailyLimitReached(availableAt: DateTime(2026, 11, 5, 8, 10).toUtc()),
        now: now.toUtc(),
      );

      expect(text, endsWith('Sledeća se oslobađa sutra u 08:10.'));
    });

    test('a too long rejection reason shows its length and the limit', () {
      expect(
        domainErrorText(const RejectionReasonTooLong(312), now: now.toUtc()),
        'Razlog je predugačak (312/300). Skrati ga.',
      );
    });
  });

  group('analysisFailureText', () {
    test('every reason has its own sentence', () {
      final texts = AnalysisFailure.values.map(analysisFailureText).toSet();

      expect(texts, hasLength(AnalysisFailure.values.length));
      expect(analysisFailureText(AnalysisFailure.unavailable), 'Video nije dostupan (privatan ili obrisan).');
    });
  });
}
