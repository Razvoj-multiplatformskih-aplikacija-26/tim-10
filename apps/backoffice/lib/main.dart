import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'dependencies.dart';

void main() {
  usePathUrlStrategy(); // on the web the address is /queue, without a "#"
  runApp(BackofficeApp(dependencies: AppDependencies.fake()));
}
