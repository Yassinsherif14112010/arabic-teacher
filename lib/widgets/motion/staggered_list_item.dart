import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Reusable staggered entrance wrapper for lists, tables, and statistics cards:
/// - Applies subtle upward slide (10px) and opacity fade-in
/// - Calculates automatic staggered timing based on item index (e.g. 40ms * index)
/// - Respects system reduce-motion settings by disabling entrance transitions
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int maxStaggerIndex;
  final Duration delay;
  final Duration duration;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.maxStaggerIndex = 12,
    this.delay = const Duration(milliseconds: 35),
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    // Cap staggered delay so large lists don't wait indefinitely for items far down
    final effectiveIndex = index > maxStaggerIndex ? maxStaggerIndex : index;
    final totalDelay = delay * effectiveIndex;

    return child
        .animate(delay: totalDelay)
        .fade(duration: duration, curve: Curves.easeOut)
        .slideY(
          begin: 0.08,
          end: 0.0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}
