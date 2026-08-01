import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_teacher_flutter/services/auth/auth_validator.dart';

void main() {
  group('Enterprise Security - AuthValidator Unit Tests', () {
    test('Email normalization trims whitespace and converts to lower case', () {
      final res = AuthValidator.normalizeAndValidateEmail('   Teacher.Admin@SCHOOL.EG  \n');
      expect(res, equals('teacher.admin@school.eg'));
    });

    test('Email validation rejects malformed input without exposing internals', () {
      expect(AuthValidator.normalizeAndValidateEmail('invalid-email-string'), isNull);
      expect(AuthValidator.normalizeAndValidateEmail('no-domain@'), isNull);
      expect(AuthValidator.normalizeAndValidateEmail(''), isNull);
    });

    test('Password complexity verification detects short or breached passwords', () {
      final errorsShort = AuthValidator.validatePassword('aB1!');
      expect(errorsShort.isNotEmpty, isTrue);
      expect(errorsShort.any((e) => e.contains('8 أحرف')), isTrue);

      final errorsBreached = AuthValidator.validatePassword('12345678');
      expect(errorsBreached.isNotEmpty, isTrue);
      expect(errorsBreached.any((e) => e.contains('ضعيفة وشائعة')), isTrue);
    });

    test('Password complexity verification approves enterprise-grade passwords', () {
      final errors = AuthValidator.validatePassword('Arabi!Teacher@Platform#2026');
      expect(errors, isEmpty);
    });

    test('Password strength meter calculates correct score from 0 to 4', () {
      expect(AuthValidator.calculatePasswordStrength('password'), equals(0));
      expect(AuthValidator.calculatePasswordStrength('abc12345'), equals(1));
      expect(AuthValidator.calculatePasswordStrength('Arabi!Teacher@Platform#2026'), equals(4));
    });

    test('Payload sanitization protects against oversized input injection', () {
      final superLong = 'A' * 1000;
      final sanitized = AuthValidator.sanitizePayload(superLong, maxLen: 100);
      expect(sanitized.length, equals(100));
    });
  });
}
