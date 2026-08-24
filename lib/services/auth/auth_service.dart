import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../sync_service.dart';
import '../database_service.dart';
import 'auth_validator.dart';
import 'auth_rate_limiter.dart';

/// Enterprise Authentication Service operating with Supabase Cloud Auth
/// and a secure offline encrypted storage fallback (DPAPI / Web Crypto).
class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _kSessionEmailKey = 'sec_auth_email';
  static const String _kOfflinePasswordHashKey = 'sec_offline_pwd_hash';
  static const String _kOfflineSaltKey = 'sec_offline_salt';

  static String? _currentEmail;

  static String? get currentUserEmail => _currentEmail;
  static bool get isLoggedIn => _currentEmail != null;

  /// Restores saved user session on startup without exposing tokens.
  static Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberEnabled = prefs.getBool('remember_me_enabled') ?? true;
      if (!rememberEnabled) {
        _currentEmail = null;
        return false;
      }

      // 1. Check if Supabase client has an active cloud session
      try {
        if (SyncService.isConfigured && Supabase.instance.client.auth.currentSession != null) {
          _currentEmail = Supabase.instance.client.auth.currentUser?.email;
          await DatabaseService.logAuthEvent(
            eventType: 'session_restored',
            message: 'Supabase cloud JWT session automatically refreshed and restored.',
          );
          return true;
        }
      } catch (_) {
        // Supabase not initialized or unreachable — continue to local fallback
      }

      // 2. Fallback to encrypted secure local storage session or remember me email
      final storedEmail = prefs.getString('remember_me_email') ?? await _storage.read(key: _kSessionEmailKey);
      if (storedEmail != null && storedEmail.isNotEmpty) {
        _currentEmail = storedEmail;
        await DatabaseService.logAuthEvent(
          eventType: 'session_restored',
          message: 'Encrypted local session restored successfully.',
        );
        return true;
      }
    } catch (_) {
      // Ignore storage read failures and start unauthenticated
    }
    return false;
  }

  /// Secure login implementation handling rate limiting, lockout, and generic error sanitization.
  /// Tries Supabase cloud auth first; on ANY network/connection failure automatically
  /// falls back to offline secure authentication so the app works without internet.
  static Future<void> login({required String rawEmail, required String rawPassword, bool rememberMe = true}) async {
    final email = AuthValidator.normalizeAndValidateEmail(rawEmail);
    if (email == null || rawPassword.isEmpty) {
      throw Exception('تنسيق البريد الإلكتروني أو كلمة المرور غير صحيح.');
    }

    if (AuthRateLimiter.isLockedOut(email)) {
      final secs = AuthRateLimiter.secondsUntilUnlock(email);
      throw Exception('تم تأمين الحساب مؤقتاً لحمايته. الزم المحاولة بعد ${secs ~/ 60} دقيقة.');
    }

    bool cloudLoginSucceeded = false;
    bool shouldFallbackOffline = false;

    // ── Step 1: Try Supabase cloud auth if configured ──
    if (SyncService.isConfigured) {
      try {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: rawPassword,
        );
        if (response.user == null) {
          throw const AuthException(AuthRateLimiter.genericErrorMessage);
        }
        _currentEmail = response.user!.email;
        cloudLoginSucceeded = true;
      } on AuthException catch (e) {
        final lowerMsg = e.message.toLowerCase();
        final isNetworkError = lowerMsg.contains('socket') ||
            lowerMsg.contains('host lookup') ||
            lowerMsg.contains('network') ||
            lowerMsg.contains('clientexception') ||
            lowerMsg.contains('connection');
        if (isNetworkError) {
          // Network unreachable → fall back to offline
          shouldFallbackOffline = true;
        } else if (lowerMsg.contains('invalid') || lowerMsg.contains('credentials') || lowerMsg.contains('user not found')) {
          await AuthRateLimiter.recordFailedLogin(email);
          throw Exception(AuthRateLimiter.genericErrorMessage);
        } else if (lowerMsg.contains('email not confirmed') || lowerMsg.contains('unconfirmed')) {
          throw Exception('البريد الإلكتروني غير مفعل بَعد. يرجى مراجعة صندوق بريدك للضغط على رابط التفعيل.');
        } else {
          // Unknown Supabase error → try offline as last resort
          shouldFallbackOffline = true;
        }
      } catch (e) {
        // Any other error (SocketException, ClientException, etc.) → offline fallback
        final msg = e.toString().toLowerCase();
        final isNetworkError = msg.contains('socket') ||
            msg.contains('host lookup') ||
            msg.contains('network') ||
            msg.contains('clientexception') ||
            msg.contains('connection') ||
            msg.contains('supabase') ||
            msg.contains('initialize');
        if (isNetworkError) {
          shouldFallbackOffline = true;
        } else {
          // For truly unknown errors, still try offline instead of blocking the user
          shouldFallbackOffline = true;
        }
      }
    } else {
      // Supabase not configured at all → go straight to offline
      shouldFallbackOffline = true;
    }

    // ── Step 2: Offline fallback authentication ──
    if (!cloudLoginSucceeded && shouldFallbackOffline) {
      try {
        final storedHash = await _storage.read(key: _kOfflinePasswordHashKey);
        final salt = await _storage.read(key: _kOfflineSaltKey) ?? 'default_salt_2026';

        if (storedHash != null) {
          final computedHash = _hashPassword(rawPassword, salt);
          if (computedHash != storedHash) {
            await AuthRateLimiter.recordFailedLogin(email);
            throw Exception(AuthRateLimiter.genericErrorMessage);
          }
        } else {
          // No offline user registered yet → auto-provision primary teacher account
          final newSalt = DateTime.now().millisecondsSinceEpoch.toString();
          final newHash = _hashPassword(rawPassword, newSalt);
          await _storage.write(key: _kOfflineSaltKey, value: newSalt);
          await _storage.write(key: _kOfflinePasswordHashKey, value: newHash);
          await DatabaseService.logAuthEvent(
            eventType: 'register_success',
            message: 'Primary offline secure administrator account provisioned.',
          );
        }
        _currentEmail = email;
      } catch (e) {
        if (e.toString().contains(AuthRateLimiter.genericErrorMessage)) rethrow;
        await AuthRateLimiter.recordFailedLogin(email);
        throw Exception(AuthRateLimiter.genericErrorMessage);
      }
    }

    // ── Step 3: Save session ──
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me_enabled', rememberMe);
    if (rememberMe) {
      await prefs.setString('remember_me_email', email);
      await _storage.write(key: _kSessionEmailKey, value: email);
    } else {
      await prefs.remove('remember_me_email');
      await _storage.delete(key: _kSessionEmailKey);
    }
    await AuthRateLimiter.recordSuccessfulLogin(email);
  }

  /// Secure Sign Up implementation with complexity checks and email verification handling.
  static Future<void> register({required String rawEmail, required String rawPassword, required String confirmPassword}) async {
    final email = AuthValidator.normalizeAndValidateEmail(rawEmail);
    if (email == null) {
      throw Exception('البريد الإلكتروني غير صالح. يرجى كتابته بصيغة صحيحة.');
    }
    if (rawPassword != confirmPassword) {
      throw Exception('كلتا كلمتي المرور غير متطابقين.');
    }
    final errors = AuthValidator.validatePassword(rawPassword);
    if (errors.isNotEmpty) {
      throw Exception(errors.join(' '));
    }

    // ── Try Supabase cloud registration first, fallback to offline ──
    bool cloudRegisterSucceeded = false;
    bool shouldFallbackOffline = false;

    if (SyncService.isConfigured) {
      try {
        final res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: rawPassword,
        );
        if (res.user != null && res.session == null) {
          await DatabaseService.logAuthEvent(
            eventType: 'register_verify',
            message: 'Registration initiated; awaiting email verification.',
          );
          throw Exception('تم إنشاء الحساب بأمان! يرجى مراجعة بريدك الإلكتروني لتفعيل الحساب.');
        }
        _currentEmail = email;
        cloudRegisterSucceeded = true;
      } on AuthException catch (e) {
        final lowerMsg = e.message.toLowerCase();
        final isNetworkError = lowerMsg.contains('socket') ||
            lowerMsg.contains('host lookup') ||
            lowerMsg.contains('network') ||
            lowerMsg.contains('clientexception') ||
            lowerMsg.contains('connection');
        if (isNetworkError) {
          shouldFallbackOffline = true;
        } else if (e.statusCode == '429' || lowerMsg.contains('rate') || lowerMsg.contains('after')) {
          throw Exception('لدواعي الأمن وحظر التكرار السريع، يرجى الانتظار دقيقة واحدة قبل إرسال طلب تفعيل جديد.');
        } else if (lowerMsg.contains('already registered') || lowerMsg.contains('exists')) {
          throw Exception('هذا البريد الإلكتروني مسجل مسبقاً في المنصة. يرجى التوجه لصفحة تسجيل الدخول مباشرة.');
        } else {
          // Unknown error → try offline
          shouldFallbackOffline = true;
        }
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('socket') || msg.contains('host lookup') || msg.contains('network') ||
            msg.contains('clientexception') || msg.contains('connection') ||
            msg.contains('supabase') || msg.contains('initialize')) {
          shouldFallbackOffline = true;
        } else {
          // Always fallback offline for unknown errors during cloud operation to ensure offline-first reliability
          shouldFallbackOffline = true;
        }
      }
    } else {
      shouldFallbackOffline = true;
    }

    // ── Offline fallback registration ──
    if (!cloudRegisterSucceeded && shouldFallbackOffline) {
      final newSalt = DateTime.now().millisecondsSinceEpoch.toString();
      final newHash = _hashPassword(rawPassword, newSalt);
      await _storage.write(key: _kOfflineSaltKey, value: newSalt);
      await _storage.write(key: _kOfflinePasswordHashKey, value: newHash);
      _currentEmail = email;
      await DatabaseService.logAuthEvent(
        eventType: 'register_success',
        message: 'Offline administrator registered successfully.',
      );
    }

    await _storage.write(key: _kSessionEmailKey, value: email);
  }

  /// Secure multi-device sign out and session invalidation.
  static Future<void> logout() async {
    try {
      if (SyncService.isConfigured && Supabase.instance.client.auth.currentSession != null) {
        // Revoke tokens globally on all devices if supported
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
      }
    } catch (_) {}
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me_enabled');
    await prefs.remove('remember_me_email');
    await _storage.delete(key: _kSessionEmailKey);
    _currentEmail = null;
    await DatabaseService.logAuthEvent(
      eventType: 'logout',
      message: 'User session logged out securely.',
    );
  }

  /// Secure password reset request without enumerating user existence.
  static Future<void> requestPasswordReset(String rawEmail) async {
    final email = AuthValidator.normalizeAndValidateEmail(rawEmail);
    if (email == null) {
      throw Exception('البريد الإلكتروني غير صالح.');
    }
    await DatabaseService.logAuthEvent(
      eventType: 'password_reset_request',
      message: 'Password reset request initiated.',
    );
    if (SyncService.isConfigured) {
      try {
        await Supabase.instance.client.auth.resetPasswordForEmail(email);
      } catch (_) {
        // Swallow exception to prevent user account enumeration
      }
    }
  }

  static String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password:$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
