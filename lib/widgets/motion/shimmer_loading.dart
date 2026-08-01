import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Reusable skeleton shimmer loader for statistics cards and list rows:
/// - Produces smooth light and dark mode shimmer sweeps at 60 FPS
/// - Maintains identical dimensions to existing loading blocks
/// - Skips continuous shimmer animation if Reduce Motion is enabled in OS
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF4A5568) : const Color(0xFFF7FAFC);

    final container = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) {
      return container;
    }

    return container
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(
          duration: const Duration(milliseconds: 1400),
          color: highlightColor,
          blendMode: BlendMode.srcOver,
        );
  }
}
