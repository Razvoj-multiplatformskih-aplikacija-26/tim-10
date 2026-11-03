import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../identifiers.dart';
import 'entry_content.dart';
import 'entry_status.dart';
import 'video_link.dart';

/// Where an entry came from.
sealed class EntrySource {
  const EntrySource();
}

/// One item of a video. A video with three recipes gives three entries with the same [link] and
/// [itemIndex] 0, 1 and 2 of [itemCount] 3 (README: "each item becomes its own entry").
@immutable
final class FromVideo extends EntrySource {
  const FromVideo({required this.link, this.itemIndex = 0, this.itemCount = 1});

  final VideoLink link;
  final int itemIndex;
  final int itemCount;

  @override
  bool operator ==(Object other) =>
      other is FromVideo && other.link == link && other.itemIndex == itemIndex && other.itemCount == itemCount;

  @override
  int get hashCode => Object.hash(link, itemIndex, itemCount);
}

/// Typed in by the user (after KT1).
final class Manual extends EntrySource {
  const Manual();

  @override
  bool operator ==(Object other) => other is Manual;

  @override
  int get hashCode => (Manual).hashCode;
}

/// Restaurant: "I would go back" (Da / Možda / Ne).
enum WouldReturn { yes, maybe, no }

/// What only the owner sees: never shown to an editor and never part of the catalog (R7).
///
/// Kept apart from [Entry.content], so editing it never changes what the AI extracted. Photos come in KT3.
@immutable
final class PersonalLayer {
  const PersonalLayer({this.note = '', this.spent, this.wouldReturn, this.modifications});

  final String note;

  /// Restaurant: how much was spent, in dinars (money is an `int` in the smallest unit).
  final int? spent;

  final WouldReturn? wouldReturn;

  /// Recipe: the user's own changes.
  final String? modifications;

  @override
  bool operator ==(Object other) =>
      other is PersonalLayer &&
      other.note == note &&
      other.spent == spent &&
      other.wouldReturn == wouldReturn &&
      other.modifications == modifications;

  @override
  int get hashCode => Object.hash(note, spent, wouldReturn, modifications);
}

/// The main concept: one recipe or one restaurant in a user's library.
@immutable
final class Entry {
  const Entry({
    required this.id,
    required this.owner,
    required this.source,
    required this.status,
    required this.createdAt,
    this.content,
    this.personal = const PersonalLayer(),
    this.analysisRequests = const [],
  });

  final EntryId id;
  final UserId owner;
  final EntrySource source;

  /// `null` until the analysis is done (in [Queued], [Analyzing] and [AnalysisFailed]).
  final EntryContent? content;
  final EntryStatus status;
  final PersonalLayer personal;
  final DateTime createdAt;

  /// When an analysis of this entry was requested: the new link, then every retry. Empty when the result was copied
  /// from an existing analysis (R4). The daily limit (R2) counts these times.
  final List<DateTime> analysisRequests;

  /// A change makes a new entry; id, owner, source and creation time never change.
  Entry copyWith({
    EntryContent? content,
    EntryStatus? status,
    PersonalLayer? personal,
    List<DateTime>? analysisRequests,
  }) => Entry(
    id: id,
    owner: owner,
    source: source,
    status: status ?? this.status,
    createdAt: createdAt,
    content: content ?? this.content,
    personal: personal ?? this.personal,
    analysisRequests: analysisRequests ?? this.analysisRequests,
  );

  @override
  bool operator ==(Object other) =>
      other is Entry &&
      other.id == id &&
      other.owner == owner &&
      other.source == source &&
      other.content == content &&
      other.status == status &&
      other.personal == personal &&
      other.createdAt == createdAt &&
      const ListEquality<DateTime>().equals(other.analysisRequests, analysisRequests);

  @override
  int get hashCode =>
      Object.hash(id, owner, source, content, status, personal, createdAt, Object.hashAll(analysisRequests));

  @override
  String toString() => 'Entry(${id.value}, ${status.runtimeType})';
}
