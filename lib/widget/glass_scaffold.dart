import 'package:flutter/material.dart';

class GlassScaffold extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;

  const GlassScaffold({
    super.key,
    required this.child,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF111218), // Dark slate grey top
              Color(0xFF07080C), // Deep obsidian bottom
            ],
          ),
        ),
        child: child,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}