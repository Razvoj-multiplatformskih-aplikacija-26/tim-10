import 'package:flutter/material.dart';

/// M-03, the start screen.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Text('Biblioteka', style: Theme.of(context).textTheme.headlineLarge)),
    );
  }
}
