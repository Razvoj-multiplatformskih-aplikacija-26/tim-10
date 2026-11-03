import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// A tab that comes after KT1: it says so, instead of showing an empty screen.
class LaterScreen extends StatelessWidget {
  const LaterScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.screen),
            child: EmptyState(title: title, message: 'Ovaj deo stiže u sledećoj verziji aplikacije.'),
          ),
        ),
      ),
    );
  }
}
