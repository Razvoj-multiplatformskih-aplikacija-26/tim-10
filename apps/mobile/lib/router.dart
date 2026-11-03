import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_shell.dart';
import 'screens/later_screen.dart';
import 'screens/library_screen.dart';

const libraryPath = '/entries';
const addVideoPath = '/entries/new';

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
            routes: [GoRoute(path: libraryPath, builder: (context, state) => const LibraryScreen())],
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
