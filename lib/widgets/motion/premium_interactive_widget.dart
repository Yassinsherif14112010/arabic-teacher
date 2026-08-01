import 'package:flutter/material.dart';

/// Reusable interactive wrapper providing world-class tactile feedback:
/// - Smooth 0.98x press scale with elastic bounce recovery
/// - Subtle Web/Desktop mouse hover elevation and shadow transition
/// - Automatic compliance with system Reduce Motion preferences
/// - 100% zero visual layout alteration when idle
class PremiumInteractiveWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enableHoverGlow;
  final double scaleOnPress;

  const PremiumInteractiveWidget({
    super.key,
    required this.child,
    this.onTap,
    this.enableHoverGlow = false,
    this.scaleOnPress = 0.97,
  });

  @override
  State<PremiumInteractiveWidget> createState() => _PremiumInteractiveWidgetState();
}

class _PremiumInteractiveWidgetState extends State<PremiumInteractiveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleOnPress).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null || MediaQuery.disableAnimationsOf(context)) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null || MediaQuery.disableAnimationsOf(context)) return;
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    Widget content = widget.child;
    if (!disableAnimations && widget.enableHoverGlow && _isHovered) {
      content = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.child,
      );
    }

    if (disableAnimations) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: content,
        ),
      ),
    );
  }
}
