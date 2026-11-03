import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';

enum _Item { refresh, failNext, emptyNext }

/// The menu in the library's title row: refresh, and under `kDebugMode` two items for the defense. They make the next
/// request fail or the next load come back empty; the screen stays the same, only the fake repository behaves differently.
class LibraryMenu extends StatelessWidget {
  const LibraryMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final fake = context.read<AppDependencies>().fakeEntries;
    return PopupMenuButton<_Item>(
      tooltip: 'Još',
      icon: const AppIcon(AppIcons.more),
      onSelected: (item) {
        switch (item) {
          case _Item.refresh:
            context.read<EntriesBloc>().add(const EntriesRequested());
          case _Item.failNext:
            fake?.failingRequests = 1;
          case _Item.emptyNext:
            fake?.emptyResponses = 1;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: _Item.refresh, child: Text('Osveži')),
        if (kDebugMode && fake != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(value: _Item.failNext, child: Text('Simuliraj grešku')),
          const PopupMenuItem(value: _Item.emptyNext, child: Text('Prazan odgovor')),
        ],
      ],
    );
  }
}
