import 'package:backoffice/app.dart';
import 'package:backoffice/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_cases/use_cases.dart';

final testNow = DateTime.utc(2026, 11, 4, 12);

AppDependencies fakeDependencies({Duration latency = Duration.zero}) =>
    AppDependencies.fake(clock: FixedClock(testNow), latency: latency);

Widget appWith(AppDependencies dependencies, {String location = '/queue'}) =>
    BackofficeApp(dependencies: dependencies, initialLocation: location);

/// A desktop window, wide enough for the table and the panel.
void useWideWindow(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 800);
  addTearDown(tester.view.reset);
}
