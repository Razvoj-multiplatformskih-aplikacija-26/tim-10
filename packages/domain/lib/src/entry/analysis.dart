import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../errors.dart';
import '../identifiers.dart';
import '../result.dart';
import 'entry.dart';
import 'entry_content.dart';
import 'entry_status.dart';
import 'video_link.dart';

/// A successful analysis of one video: one or more items, each a recipe or a restaurant
/// ("3 recipes for breakfast", "top 10 restaurants in London").
///
/// A failed analysis (not food, unavailable, timeout) is not a result; the `VideoAnalyzer` port reports it.
@immutable
final class AnalysisResult {
  const AnalysisResult({required this.link, required this.items, this.author, this.thumbnail})
    : assert(items.length > 0);

  final VideoLink link;
  final List<EntryContent> items;

  /// Who posted the video, and a frame of it; every entry made from this result gets them (see [FromVideo]).
  final String? author;
  final String? thumbnail;

  @override
  bool operator ==(Object other) =>
      other is AnalysisResult &&
      other.link == link &&
      const ListEquality<EntryContent>().equals(other.items, items) &&
      other.author == author &&
      other.thumbnail == thumbnail;

  @override
  int get hashCode => Object.hash(link, Object.hashAll(items), author, thumbnail);
}

/// README: "if a video has several items, each becomes its own entry".
///
/// The entry that waited for the analysis becomes item 0 and keeps its id; items 1..N-1 are new entries whose ids
/// come from [newId] (the repository or the server gives ids, not the domain). All of them wait for the user's review.
///
/// R2: one video is one analysis, so only item 0 keeps the analysis request; the others cost nothing.
Result<List<Entry>> entriesFromAnalysis(
  Entry queued,
  AnalysisResult result, {
  required DateTime now,
  required EntryId Function(int itemIndex) newId,
}) {
  final next = AwaitingReview(analyzedAt: now.toUtc());
  if (!canTransition(queued.status, next)) return Failure(InvalidTransition(from: queued.status, to: next));

  final count = result.items.length;
  return Success([
    for (var i = 0; i < count; i++)
      Entry(
        id: i == 0 ? queued.id : newId(i),
        owner: queued.owner,
        source: FromVideo(
          link: result.link,
          itemIndex: i,
          itemCount: count,
          author: result.author,
          thumbnail: result.thumbnail,
        ),
        status: next,
        createdAt: queued.createdAt,
        content: result.items[i],
        analysisRequests: i == 0 ? queued.analysisRequests : const [],
      ),
  ]);
}
