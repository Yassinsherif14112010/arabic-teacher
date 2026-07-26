import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_teacher_flutter/providers/app_provider.dart';

void main() {
  group('AppProvider', () {
    test('generateBarcode returns 6-digit string', () {
      final provider = AppProvider();
      final code = provider.generateBarcode();
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
      expect(int.parse(code), greaterThanOrEqualTo(100000));
      expect(int.parse(code), lessThanOrEqualTo(999999));
    });

    test('generateBarcode produces unique codes', () {
      final provider = AppProvider();
      final codes = List.generate(20, (_) => provider.generateBarcode());
      final unique = codes.toSet();
      // All 20 should be unique (extremely unlikely to collide)
      expect(unique.length, 20);
    });

    test('todayDateString has correct format', () {
      final provider = AppProvider();
      final dateStr = provider.todayDateString;
      // Should match yyyy-MM-dd
      final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      expect(regex.hasMatch(dateStr), isTrue);
    });

    test('initial state has empty lists', () {
      final provider = AppProvider();
      expect(provider.students, isEmpty);
      expect(provider.groups, isEmpty);
      expect(provider.payments, isEmpty);
      expect(provider.grades, isEmpty);
      expect(provider.feeSettings, isEmpty);
    });

    test('findStudentByBarcode returns null when no students', () {
      final provider = AppProvider();
      expect(provider.findStudentByBarcode('123456'), isNull);
    });

    test('attendanceRate is 0 when no students', () {
      final provider = AppProvider();
      expect(provider.attendanceRate, 0);
    });

    test('paidStudents is 0 initially', () {
      final provider = AppProvider();
      expect(provider.paidStudents, 0);
    });
  });
}
