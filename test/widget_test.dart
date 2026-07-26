import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arabic_teacher_flutter/providers/app_provider.dart';
import 'package:arabic_teacher_flutter/providers/theme_provider.dart';
import 'package:arabic_teacher_flutter/widgets/stat_card.dart';
import 'package:arabic_teacher_flutter/widgets/empty_state.dart';
import 'package:arabic_teacher_flutter/widgets/grade_badge.dart';
import 'package:arabic_teacher_flutter/theme/app_theme.dart';

// Helper to wrap a widget with required providers
Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AppProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  // ─── StatCard ─────────────────────────────────────────────────────────────
  group('StatCard widget', () {
    testWidgets('renders title and value', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(
          title: 'إجمالي الطلاب',
          value: '42',
          icon: Icons.people,
          iconColor: Colors.blue,
          borderColor: Colors.blue,
        ),
      ));
      expect(find.text('إجمالي الطلاب'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(
          title: 'حضور اليوم',
          value: '15',
          subtitle: 'حاضرين حتى الآن',
          icon: Icons.check_circle,
          iconColor: Colors.green,
          borderColor: Colors.green,
        ),
      ));
      expect(find.text('حاضرين حتى الآن'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(
          title: 'نسبة الحضور',
          value: '80%',
          icon: Icons.trending_up,
          iconColor: Colors.orange,
          borderColor: Colors.orange,
        ),
      ));
      // Only title and value, no subtitle
      expect(find.text('نسبة الحضور'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
    });
  });

  // ─── EmptyState ───────────────────────────────────────────────────────────
  group('EmptyState widget', () {
    testWidgets('renders message', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          icon: Icons.people_outline,
          message: 'لا يوجد طلاب مسجلون',
        ),
      ));
      expect(find.text('لا يوجد طلاب مسجلون'), findsOneWidget);
    });

    testWidgets('renders action button when provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        EmptyState(
          icon: Icons.add,
          message: 'لا توجد بيانات',
          actionLabel: 'إضافة',
          onAction: () => tapped = true,
        ),
      ));
      expect(find.text('إضافة'), findsOneWidget);
      await tester.tap(find.text('إضافة'));
      expect(tapped, isTrue);
    });

    testWidgets('does not render button when actionLabel is null',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          icon: Icons.info_outline,
          message: 'لا توجد نتائج',
        ),
      ));
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  // ─── GradeBadge ───────────────────────────────────────────────────────────
  group('GradeBadge widget', () {
    testWidgets('renders grade text', (tester) async {
      await tester.pumpWidget(_wrap(
        const GradeBadge(grade: 'الصف الثالث الثانوي'),
      ));
      expect(find.text('الصف الثالث الثانوي'), findsOneWidget);
    });
  });

  // ─── AppTheme ─────────────────────────────────────────────────────────────
  group('AppTheme', () {
    test('dark theme has correct primary color', () {
      final theme = AppTheme.dark;
      expect(theme.colorScheme.primary, AppColors.primary);
    });

    test('light theme has correct brightness', () {
      final theme = AppTheme.light;
      expect(theme.brightness, Brightness.light);
    });

    test('dark theme has correct brightness', () {
      final theme = AppTheme.dark;
      expect(theme.brightness, Brightness.dark);
    });
  });

  // ─── ThemeProvider ────────────────────────────────────────────────────────
  group('ThemeProvider', () {
    test('defaults to dark mode', () {
      final provider = ThemeProvider();
      expect(provider.mode, ThemeMode.dark);
      expect(provider.isDark, isTrue);
    });
  });
}
