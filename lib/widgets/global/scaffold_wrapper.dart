import 'package:flutter/material.dart';

/// A wrapper widget that provides the main layout structure for the app
class ScaffoldWrapper extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final FloatingActionButton? floatingActionButton;
  final Color? backgroundColor;

  const ScaffoldWrapper({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.drawer,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
    );
  }
}