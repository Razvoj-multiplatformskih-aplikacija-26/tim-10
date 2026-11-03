import 'package:domain/domain.dart';

/// Port: "analyse this video". In KT1 a fake with prepared results plays the AI; from KT2 the server downloads the
/// video, takes key frames, transcribes the speech and extracts the items.
abstract interface class VideoAnalyzer {
  Future<AnalysisOutcome> analyze(VideoLink link);
}

/// What an analysis ends with: the items of the video, or why there are none.
sealed class AnalysisOutcome {
  const AnalysisOutcome();
}

final class AnalysisSucceeded extends AnalysisOutcome {
  const AnalysisSucceeded(this.result);

  final AnalysisResult result;

  @override
  bool operator ==(Object other) => other is AnalysisSucceeded && other.result == result;

  @override
  int get hashCode => result.hashCode;
}

final class AnalysisFailedWith extends AnalysisOutcome {
  const AnalysisFailedWith(this.reason);

  final AnalysisFailure reason;

  @override
  bool operator ==(Object other) => other is AnalysisFailedWith && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}
