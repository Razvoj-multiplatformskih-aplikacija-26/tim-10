/// The current time comes from outside, like any other platform service.
///
/// [SystemClock] is the only place in the shared packages that calls `DateTime.now()`. Tests use [FixedClock], so
/// "24 hours ago" (R2) means the same thing on every run.
abstract interface class Clock {
  DateTime now();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

final class FixedClock implements Clock {
  const FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant.toUtc();
}
