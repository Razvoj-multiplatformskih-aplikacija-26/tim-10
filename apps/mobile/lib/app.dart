import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'router.dart';

class MobileApp extends StatefulWidget {
  const MobileApp({super.key, required this.dependencies, this.initialLocation = libraryPath});

  final AppDependencies dependencies;
  final String initialLocation;

  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  late final GoRouter _router = buildRouter(initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: widget.dependencies,
      child: BlocProvider(
        // Above the router: the library and the detail of an entry read the same state.
        create: (_) => widget.dependencies.entriesBloc()..add(const EntriesRequested()),
        child: MaterialApp.router(
          title: 'ReelToMeal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
          supportedLocales: const [Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: _router,
        ),
      ),
    );
  }
}
