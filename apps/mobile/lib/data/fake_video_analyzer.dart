import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

/// Plays the AI in KT1: known videos have results written in advance, any other link "is not food".
///
/// So the demo shows both a successful analysis and a failed one. From KT2 the server analyses the video and only
/// `dependencies.dart` changes.
final class FakeVideoAnalyzer implements VideoAnalyzer {
  FakeVideoAnalyzer(this.known, {this.latency = const Duration(milliseconds: 1200)});

  /// The result of each known video (its items, author and frame), by its canonical link.
  final Map<VideoLink, AnalysisResult> known;

  /// How long "the AI" takes.
  final Duration latency;

  @override
  Future<AnalysisOutcome> analyze(VideoLink link) async {
    await Future<void>.delayed(latency);
    final result = known[link];
    if (result == null) return const AnalysisFailedWith(AnalysisFailure.notFood);
    return AnalysisSucceeded(result);
  }
}
