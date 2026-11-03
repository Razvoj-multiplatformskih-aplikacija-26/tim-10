import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../identifiers.dart';
import '../rules/duplicates.dart';
import 'entry.dart';
import 'entry_content.dart';
import 'entry_status.dart';

/// A restaurant already in the catalog that may be the same as a proposal (R5).
@immutable
final class CatalogMatch {
  const CatalogMatch({required this.id, required this.content});

  final EntryId id;
  final RestaurantContent content;

  @override
  bool operator ==(Object other) => other is CatalogMatch && other.id == id && other.content == content;

  @override
  int get hashCode => Object.hash(id, content);
}

/// One row of the editor's queue: what a user proposed for the catalog.
///
/// R7 by type: there is no `PersonalLayer` here, so no backoffice screen can show a user's notes by mistake.
@immutable
final class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.proposedBy,
    required this.source,
    required this.content,
    required this.submittedAt,
    this.duplicates = const [],
  });

  final EntryId id;
  final UserId proposedBy;
  final EntrySource source;
  final EntryContent content;
  final DateTime submittedAt;

  /// Restaurants in the catalog the editor should compare this proposal with. Always empty for a recipe.
  final List<CatalogMatch> duplicates;

  /// The row for [entry], or `null` when it is not waiting for an editor.
  static ReviewItem? of(Entry entry, {required List<Entry> catalog}) {
    final status = entry.status;
    final content = entry.content;
    if (status is! PendingApproval || content == null) return null;
    return ReviewItem(
      id: entry.id,
      proposedBy: entry.owner,
      source: entry.source,
      content: content,
      submittedAt: status.submittedAt,
      duplicates: _duplicatesOf(content, catalog),
    );
  }

  static List<CatalogMatch> _duplicatesOf(EntryContent content, List<Entry> catalog) => switch (content) {
    RecipeContent() => const [],
    RestaurantContent() => [
      for (final match in possibleDuplicates(content, catalog))
        if (match.content case final RestaurantContent existing) CatalogMatch(id: match.id, content: existing),
    ],
  };

  @override
  bool operator ==(Object other) =>
      other is ReviewItem &&
      other.id == id &&
      other.proposedBy == proposedBy &&
      other.source == source &&
      other.content == content &&
      other.submittedAt == submittedAt &&
      const ListEquality<CatalogMatch>().equals(other.duplicates, duplicates);

  @override
  int get hashCode => Object.hash(id, proposedBy, source, content, submittedAt, Object.hashAll(duplicates));

  @override
  String toString() => 'ReviewItem(${id.value})';
}
