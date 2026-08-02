class AuthValidator {
  /// Normalizes email to trimmed lowercase and checks validity.
  static String? normalizeAndValidateEmail(String rawEmail) {
    final trimmed = rawEmail.trim().toLowerCase();
    final emailRegex = RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return null;
    }
    return trimmed;
  }

  /// Validates password complexity and returns list of error messages in Arabic if any.
  static List<String> validatePassword(String password) {
    final errors = <String>[];
    if (password.length < 8) {
      errors.add('يجب ألا تقل كلمة المرور عن 8 أحرف.');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('يجب أن تحتوي كلمة المرور على أرقام.');
    }
    return errors;
  }

  /// Returns a password strength score from 0 (very weak) to 4 (enterprise grade).
  static int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 1;
    if (password.length >= 8) score++;
    if (password.length >= 12 && password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')) || password.contains(RegExp(r'[A-Z]'))) score++;
    return score.clamp(0, 4);
  }
}
