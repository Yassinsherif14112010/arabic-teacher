class AuthRateLimiter {
  static const String genericErrorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  static final Map<String, int> _failedAttempts = {};
  static final Map<String, DateTime> _lockoutUntil = {};

  static bool isLockedOut(String email) {
    final unlockTime = _lockoutUntil[email];
    if (unlockTime != null) {
      if (DateTime.now().isBefore(unlockTime)) {
        return true;
      } else {
        _lockoutUntil.remove(email);
        _failedAttempts.remove(email);
        return false;
      }
    }
    return false;
  }

  static int secondsUntilUnlock(String email) {
    final unlockTime = _lockoutUntil[email];
    if (unlockTime == null) return 0;
    final diff = unlockTime.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  static Future<void> recordFailedLogin(String email) async {
    final count = (_failedAttempts[email] ?? 0) + 1;
    _failedAttempts[email] = count;
    if (count >= 5) {
      _lockoutUntil[email] = DateTime.now().add(const Duration(minutes: 5));
    }
  }

  static Future<void> recordSuccessfulLogin(String email) async {
    _failedAttempts.remove(email);
    _lockoutUntil.remove(email);
  }
}
