/// Enterprise-grade authentication validator and complexity verifier.
/// Implements input sanitization, normalization, and breached password detection.
class AuthValidator {
  static final RegExp _emailRegExp =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  // Common breached and dictionary passwords to block
  static const Set<String> _breachedOrWeakPasswords = {
    '123456',
    '12345678',
    '123456789',
    'password',
    'qwerty',
    'admin123',
    'teacher123',
    'arabic123',
    '111111',
    '000000',
    '123123',
    'abcdef',
  };

  /// Normalizes email by trimming whitespace and converting to lower case.
  /// Rejects malformed input by returning null if format is invalid.
  static String? normalizeAndValidateEmail(String rawEmail) {
    final trimmed = rawEmail.trim().toLowerCase();
    if (trimmed.length > 254 || trimmed.isEmpty) return null;
    if (!_emailRegExp.hasMatch(trimmed)) return null;
    return trimmed;
  }

  /// Validates password complexity.
  /// Returns a list of validation errors, or empty list if valid.
  static List<String> validatePassword(String password) {
    final errors = <String>[];
    if (password.length < 8) {
      errors.add('كلمة المرور يجب أن لا تقل عن 8 أحرف.');
    }
    if (password.length > 128) {
      errors.add('كلمة المرور طويلة جداً (الحد الأقصى 128 حرفاً).');
    }
    if (_breachedOrWeakPasswords.contains(password.toLowerCase())) {
      errors.add('كلمة المرور ضعيفة وشائعة. يرجى اختيار كلمة سر أقوى.');
    }
    if (!password.contains(RegExp(r'[A-Z]')) &&
        !password.contains(RegExp(r'[أ-ي]'))) {
      errors.add('يجب أن تحتوي على حرف كبير واحد على الأقل.');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('يجب أن تحتوي على رقم واحد على الأقل.');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_~+\-=/]'))) {
      errors.add('يجب أن تحتوي على رمز خاص واحد على الأقل (!@#\$%^&*...).');
    }
    return errors;
  }

  /// Calculates visual password strength score from 0 to 4.
  /// 0 = very weak, 1 = weak, 2 = fair, 3 = good, 4 = excellent/enterprise.
  static int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    if (_breachedOrWeakPasswords.contains(password.toLowerCase())) return 0;
    
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) {
      score++;
    }
    if (password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_~+\-=/]'))) {
      score++;
    }
    return score > 4 ? 4 : score;
  }

  /// Sanitize arbitrary string payload to avoid oversized injection attacks.
  static String sanitizePayload(String input, {int maxLen = 500}) {
    final trimmed = input.trim();
    if (trimmed.length > maxLen) {
      return trimmed.substring(0, maxLen);
    }
    return trimmed;
  }
}
