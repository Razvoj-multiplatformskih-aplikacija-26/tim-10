import 'package:domain/domain.dart';

/// The one place where a domain error becomes Serbian text.
///
/// The switch has no `default`: when the domain gets a new error, the compiler stops here until it has a message.
/// Numbers come from the domain's constants, so changing the limit there changes the message too.
/// [now] is needed only to say "danas" or "sutra" for the daily limit.
String domainErrorText(DomainError error, {required DateTime now}) => switch (error) {
  InvalidLink() => 'Ovo ne liči na link do videa. Nalepi ceo link, na primer instagram.com/reel/…',
  UnsupportedPlatform() => 'Za sada podržavamo samo Instagram i TikTok. Recept iz ovog videa možeš da uneseš ručno.',
  NotAVideoLink() => 'Ovaj link ne vodi do jednog videa. Otvori video i podeli njegov link.',
  DailyLimitReached(:final availableAt) =>
    'Iskorišćeno je svih $dailyAnalysisLimit današnjih analiza. '
        'Sledeća se oslobađa ${_dayAndTime(availableAt, now: now)}.',
  EntryBeingAnalyzed() => 'Unos se još analizira. Sačekaj da analiza završi.',
  RejectionReasonEmpty() => 'Upiši razlog odbijanja.',
  RejectionReasonTooLong(:final length) => 'Razlog je predugačak ($length/${RejectionReason.maxLength}). Skrati ga.',
  NotAllowed() => 'Nemaš dozvolu za ovu radnju.',
  InvalidTransition() => 'Ova radnja sada nije moguća.',
  NotFound() => 'Ovaj unos više ne postoji.',
};

/// Why an analysis failed, in words a user understands (the failure card, M-06).
String analysisFailureText(AnalysisFailure reason) => switch (reason) {
  AnalysisFailure.unavailable => 'Video nije dostupan (privatan ili obrisan).',
  AnalysisFailure.notFood => 'U videu nismo prepoznali recept ni restoran.',
  AnalysisFailure.timeout => 'Analiza je trajala predugo.',
  AnalysisFailure.unsupported => 'Ovaj video za sada ne možemo da analiziramo.',
};

/// "danas u 23:40" or "sutra u 08:10", in the phone's time zone. The limit window is 24 hours, so the next free
/// place is always today or tomorrow.
String _dayAndTime(DateTime at, {required DateTime now}) {
  final local = at.toLocal();
  final today = now.toLocal();
  final time = '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  final isToday = local.year == today.year && local.month == today.month && local.day == today.day;
  return isToday ? 'danas u $time' : 'sutra u $time';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');
