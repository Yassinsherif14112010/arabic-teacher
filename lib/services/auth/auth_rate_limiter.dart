import 'dart:async';
import '../database_service.dart';

/// Protects authentication endpoints against Brute Force, Credential Stuffing,
/// Timing Attacks, and User Enumeration.
class AuthRateLimiter {
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  /// Uniform generic error message to prevent user account enumeration
  static const String genericErrorMessage =
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  static final Map<String, int> _failedAttempts = {};
  static final Map<String, DateTime> _lockoutUntil = {};

  /// Checks if an email is currently temporarily locked out.
  static bool isLockedOut(String normalizedEmail) {
    final unlockTime = _lockoutUntil[normalizedEmail];
    if (unlockTime != null) {
      if (DateTime.now().isBefore(unlockTime)) {
        return true;
      } else {
        // Lockout expired, reset status
        _lockoutUntil.remove(normalizedEmail);
        _failedAttempts.remove(normalizedEmail);
        return false;
      }
    }
    return false;
  }

  /// Returns the number of seconds remaining in lockout.
  static int secondsUntilUnlock(String normalizedEmail) {
    final unlockTime = _lockoutUntil[normalizedEmail];
    if (unlockTime == null || DateTime.now().isAfter(unlockTime)) {
      return 0;
    }
    return unlockTime.difference(DateTime.now()).inSeconds;
  }

  /// Record a failed login attempt with progressive timing delays and lockout triggering.
  static Future<void> recordFailedLogin(String normalizedEmail) async {
    final current = (_failedAttempts[normalizedEmail] ?? 0) + 1;
    _failedAttempts[normalizedEmail] = current;

    // Secure audit logging without recording passwords or tokens
    await DatabaseService.logAuthEvent(
      eventType: 'login_failed',
      message: 'Failed authentication attempt (Attempt $current).',
    );

    if (current >= maxFailedAttempts) {
      _lockoutUntil[normalizedEmail] = DateTime.now().add(lockoutDuration);
      await DatabaseService.logAuthEvent(
        eventType: 'lockout_triggered',
        message: 'Account authentication locked for 15 minutes after excessive failures.',
      );
    } else if (current >= 3) {
      // Progressive response delay to mitigate automated attack velocity
      final delaySeconds = (current - 2) * 2;
      await Future.delayed(Duration(seconds: delaySeconds));
    }
  }

  /// Clear failure trackers upon successful authentication.
  static Future<void> recordSuccessfulLogin(String normalizedEmail) async {
    _failedAttempts.remove(normalizedEmail);
    _lockoutUntil.remove(normalizedEmail);
    await DatabaseService.logAuthEvent(
      eventType: 'login_success',
      message: 'Successful user session authentication.',
    );
  }
}
