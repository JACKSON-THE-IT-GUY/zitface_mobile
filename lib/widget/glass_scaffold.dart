import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: AppColors.pageBackground,
      body: Container(color: AppColors.pageBackground, child: child),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
