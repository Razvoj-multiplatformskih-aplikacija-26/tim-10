import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'dev/ui_showcase_screen.dart';

void main() {
  runApp(const MobileApp());
}

/// Until M-03 is built, the app opens the screen that shows every shared widget.
class MobileApp extends StatelessWidget {
  const MobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReelToMeal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const UiShowcaseScreen(),
    );
  }
}
