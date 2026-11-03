import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';

enum _Item { refresh, shortcuts, failNext, emptyNext }

/// The menu in the app bar: a menu, so it fits a narrow window too.
///
/// Under `kDebugMode` it also has two items for the defense: they make the next request fail or the next load come back
/// empty. The screen stays the same; only the fake repository behaves differently.
class QueueMenu extends StatelessWidget {
  const QueueMenu({super.key, required this.onRefresh, required this.onShowShortcuts});

  final VoidCallback onRefresh;
  final VoidCallback onShowShortcuts;

  @override
  Widget build(BuildContext context) {
    final fake = context.read<AppDependencies>().fakeQueue;
    return PopupMenuButton<_Item>(
      tooltip: 'Još',
      icon: const AppIcon(AppIcons.more),
      onSelected: (item) {
        switch (item) {
          case _Item.refresh:
            onRefresh();
          case _Item.shortcuts:
            onShowShortcuts();
          case _Item.failNext:
            fake?.failingRequests = 1;
          case _Item.emptyNext:
            fake?.emptyResponses = 1;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: _Item.refresh, child: Text('Osveži')),
        const PopupMenuItem(value: _Item.shortcuts, child: Text('Prečice (?)')),
        if (kDebugMode && fake != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(value: _Item.failNext, child: Text('Simuliraj grešku')),
          const PopupMenuItem(value: _Item.emptyNext, child: Text('Prazan odgovor')),
        ],
      ],
    );
  }
}
