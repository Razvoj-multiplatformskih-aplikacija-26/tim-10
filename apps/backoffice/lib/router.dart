import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';

import 'screens/queue_screen.dart';

const queuePath = '/queue';

/// The address of the queue, with the proposal open in the panel: `/queue?entry=p-3`.
String queueLocation(EntryId? selected) => selected == null ? queuePath : '$queuePath?entry=${selected.value}';

GoRouter buildRouter({String initialLocation = queuePath}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', redirect: (context, state) => queuePath),
    GoRoute(
      path: queuePath,
      builder: (context, state) {
        final entry = state.uri.queryParameters['entry'];
        return QueueScreen(selected: entry == null ? null : EntryId(entry));
      },
    ),
  ],
);
