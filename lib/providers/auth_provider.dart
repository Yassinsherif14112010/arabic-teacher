import 'package:flutter/material.dart';
import '../services/auth/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => AuthService.isLoggedIn;
  String? get currentEmail => AuthService.currentUserEmail;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      await AuthService.restoreSession();
    } catch (_) {}
    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password, {bool rememberMe = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await AuthService.login(rawEmail: email, rawPassword: password, rememberMe: rememberMe);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String confirmPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await AuthService.register(rawEmail: email, rawPassword: password, confirmPassword: confirmPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await AuthService.logout();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> requestPasswordReset(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await AuthService.requestPasswordReset(email);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }
}
