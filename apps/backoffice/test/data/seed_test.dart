import 'package:backoffice/data/seed.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 4, 12);
  final entries = demoEntries(now);
  final catalog = [
    for (final entry in entries)
      if (entry.status is Published) entry,
  ];

  test('has more than ten proposals for the wide table', () {
    expect(entries.where((entry) => entry.status is PendingApproval).length, greaterThan(10));
  });

  test('every id is unique', () {
    expect(entries.map((entry) => entry.id).toSet().length, entries.length);
  });

  test('has proposals that are possible duplicates of the catalog (R5)', () {
    final items = [for (final entry in entries) ?ReviewItem.of(entry, catalog: catalog)];

    expect(items.where((item) => item.duplicates.isNotEmpty).map((item) => item.id), [
      const EntryId('p-1'),
      const EntryId('p-4'),
    ]);
  });

  test('has a personal layer the editor must never see (R7)', () {
    expect(entries.where((entry) => entry.personal.note.isNotEmpty), isNotEmpty);
  });
}
