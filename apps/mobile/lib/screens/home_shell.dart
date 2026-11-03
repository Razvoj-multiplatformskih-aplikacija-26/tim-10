import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../router.dart';

/// The tabs at the bottom. The middle "Dodaj" is not a tab: it opens the form over the whole screen.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppTabBar(
        currentIndex: shell.currentIndex,
        onSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        onAdd: () => context.push(addVideoPath),
      ),
    );
  }
}
