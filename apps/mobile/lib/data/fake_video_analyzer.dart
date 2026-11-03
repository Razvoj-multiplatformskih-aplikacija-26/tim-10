import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

/// Plays the AI in KT1: known videos have results written in advance, any other link "is not food".
///
/// So the demo shows both a successful analysis and a failed one. From KT2 the server analyses the video and only
/// `dependencies.dart` changes.
final class FakeVideoAnalyzer implements VideoAnalyzer {
  FakeVideoAnalyzer(this.known, {this.latency = const Duration(milliseconds: 1200)});

  /// The items of each known video, by its canonical link.
  final Map<VideoLink, List<EntryContent>> known;

  /// How long "the AI" takes.
  final Duration latency;

  @override
  Future<AnalysisOutcome> analyze(VideoLink link) async {
    await Future<void>.delayed(latency);
    final items = known[link];
    if (items == null) return const AnalysisFailedWith(AnalysisFailure.notFood);
    return AnalysisSucceeded(AnalysisResult(link: link, items: items));
  }
}
