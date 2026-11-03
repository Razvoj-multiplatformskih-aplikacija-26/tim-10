import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'dependencies.dart';
import 'screens/add_video_screen.dart';
import 'screens/entry_detail_screen.dart';
import 'screens/home_shell.dart';
import 'screens/later_screen.dart';
import 'screens/library_screen.dart';

const libraryPath = '/entries';
const addVideoPath = '/entries/new';

/// The address of one entry: `/entries/d-saved`.
String entryPath(EntryId id) => '$libraryPath/${id.value}';

GoRouter buildRouter({String initialLocation = libraryPath}) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => libraryPath),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: libraryPath,
                builder: (context, state) => const LibraryScreen(),
                routes: [
                  // Before ':id', or "new" would be read as the id of an entry.
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => BlocProvider(
                      // A local Bloc: it is created with the form and closes with it.
                      create: (context) =>
                          context.read<AppDependencies>().submitLinkBloc()..add(const SubmitLinkOpened()),
                      child: const AddVideoScreen(),
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => EntryDetailScreen(id: EntryId(state.pathParameters['id']!)),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const LaterScreen(title: 'Mapa'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shopping',
                builder: (context, state) => const LaterScreen(title: 'Lista za kupovinu'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const LaterScreen(title: 'Profil'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
