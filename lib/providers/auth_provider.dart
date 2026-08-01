import 'package:flutter/foundation.dart';
import '../services/auth/auth_service.dart';

/// State management provider for user sessions, auth workflows, and feedback errors.
class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String? get currentEmail => AuthService.currentUserEmail;
  bool get isAuthenticated => AuthService.isLoggedIn;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await AuthService.restoreSession();
    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await AuthService.login(rawEmail: email, rawPassword: password);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String email, String password, String confirmPassword) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await AuthService.register(rawEmail: email, rawPassword: password, confirmPassword: confirmPassword);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await AuthService.logout();
    _setLoading(false);
    notifyListeners();
  }

  Future<bool> requestPasswordReset(String email) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await AuthService.requestPasswordReset(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
