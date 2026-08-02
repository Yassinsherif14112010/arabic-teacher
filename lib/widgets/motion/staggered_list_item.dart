import 'package:flutter/material.dart';

class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration delay;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 50),
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
