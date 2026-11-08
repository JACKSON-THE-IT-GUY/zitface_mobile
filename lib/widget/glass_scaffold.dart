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
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(color: backgroundColor, child: child),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
