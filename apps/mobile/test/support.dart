import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/dependencies.dart';
import 'package:use_cases/use_cases.dart';

final testNow = DateTime.utc(2026, 11, 4, 12);

AppDependencies fakeDependencies({Duration latency = Duration.zero}) =>
    AppDependencies.fake(clock: FixedClock(testNow), latency: latency, analysisLatency: Duration.zero);

Widget appWith(AppDependencies dependencies, {String location = '/entries'}) =>
    MobileApp(dependencies: dependencies, initialLocation: location);

/// A phone screen, tall enough for the first cards.
void usePhoneSize(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(420, 900);
  addTearDown(tester.view.reset);
}
