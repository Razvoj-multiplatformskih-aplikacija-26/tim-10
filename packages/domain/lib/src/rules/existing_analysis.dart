import '../entry/analysis.dart';
import '../entry/entry.dart';
import '../entry/entry_content.dart';
import '../entry/video_link.dart';

/// R4 (README): the same video is analysed only once, across all users.
///
/// Looks through the entries of every user for a finished analysis of [link] and returns it, so a new user gets a
/// copy at once (`Queued → AwaitingReview`) without waiting, and the system does not pay for the same analysis
/// twice. The link still counts toward the user's daily limit (R2 counts the links a user sends). Returns `null` when
/// no one has the whole analysis yet; then the video is analysed.
///
/// Only the content is copied, never anyone's personal layer. The client uses this as an estimate; the server decides
/// (KT2), so two users sending the same video at the same moment still start a single analysis.
AnalysisResult? existingAnalysisFor(VideoLink link, List<Entry> all) {
  final items = <int, EntryContent>{};
  int? itemCount;

  for (final entry in all) {
    final content = entry.content; // null while queued, analysing or failed
    if (content == null) continue;
    if (entry.source case FromVideo(link: final entryLink, :final itemIndex, itemCount: final count)
        when entryLink == link) {
      items.putIfAbsent(itemIndex, () => content);
      itemCount = count;
    }
  }

  // Every item must be there: someone may have deleted one of theirs, and nobody else may have it.
  if (itemCount == null || items.length != itemCount) return null;
  return AnalysisResult(link: link, items: [for (var i = 0; i < itemCount; i++) items[i]!]);
}
