import 'package:flutter/material.dart';

/// Provides the actual available content width to descendant widgets.
///
/// This is used by screens inside the tablet sidebar layout to determine
/// responsive behavior based on their **actual** available width rather than
/// the full screen width from [MediaQuery].
class ContentWidthProvider extends InheritedWidget {
  final double contentWidth;

  const ContentWidthProvider({
    super.key,
    required this.contentWidth,
    required super.child,
  });

  /// Returns the available content width, or falls back to
  /// [MediaQuery.of(context).size.width] if no provider is found.
  static double of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ContentWidthProvider>();
    if (provider != null) {
      return provider.contentWidth;
    }
    return MediaQuery.of(context).size.width;
  }

  @override
  bool updateShouldNotify(ContentWidthProvider oldWidget) =>
      contentWidth != oldWidget.contentWidth;
}
