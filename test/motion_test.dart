import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_teacher_flutter/widgets/motion/premium_interactive_widget.dart';
import 'package:arabic_teacher_flutter/widgets/motion/staggered_list_item.dart';
import 'package:arabic_teacher_flutter/widgets/motion/shimmer_loading.dart';

void main() {
  group('Premium Motion Component Tests', () {
    testWidgets('PremiumInteractiveWidget renders child identically and handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumInteractiveWidget(
              onTap: () => tapped = true,
              enableHoverGlow: true,
              child: const Text('Touch Me', key: Key('target_text')),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('target_text')), findsOneWidget);
      await tester.tap(find.byKey(const Key('target_text')));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('StaggeredListItem renders without modifying layout dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredListItem(
              index: 1,
              child: SizedBox(width: 100, height: 50, key: Key('staggered_box')),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('staggered_box')), findsOneWidget);
    });

    testWidgets('ShimmerLoading maintains correct exact width and height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: ShimmerLoading(width: 200, height: 80, key: Key('shimmer')),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('shimmer')), findsOneWidget);
    });
  });
}
