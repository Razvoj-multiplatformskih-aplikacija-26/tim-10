/// ReelToMeal domain: entries, their states, rules and calculations.
///
/// Pure Dart, shared by both apps, the server and the public web. No Flutter and no platform libraries here.
library;

export 'src/entry/access_policy.dart';
export 'src/entry/analysis.dart';
export 'src/entry/deletion.dart';
export 'src/entry/entry.dart';
export 'src/entry/entry_content.dart';
export 'src/entry/entry_status.dart';
export 'src/entry/rejection_reason.dart';
export 'src/entry/transitions.dart';
export 'src/entry/video_link.dart';
export 'src/errors.dart';
export 'src/identifiers.dart';
export 'src/result.dart';
export 'src/rules/daily_limit.dart';
export 'src/rules/duplicates.dart';
export 'src/rules/existing_analysis.dart';
export 'src/user.dart';
