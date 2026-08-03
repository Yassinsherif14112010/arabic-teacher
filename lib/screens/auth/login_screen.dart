import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'registration_screen.dart';
import 'password_reset_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      rememberMe: _rememberMe,
    );
    if (!success && auth.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 710;
    final cardMaxWidth = isWide ? 520.0 : 440.0;
    final outerPadding = isWide ? 40.0 : 24.0;
    final innerPadding = isWide ? 40.0 : 32.0;
    final logoSize = isWide ? 110.0 : 100.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1526) : const Color(0xFFF8FAFC),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(outerPadding),
            child: Container(
              constraints: BoxConstraints(maxWidth: cardMaxWidth),
              padding: EdgeInsets.all(innerPadding),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Logo
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 20),
                  Text(
                    'الشاعر في اللغة العربية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'منصة الأستاذ محسن شاكر - بوابة المسؤول',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Email field
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(fontFamily: 'Cairo', color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      labelStyle: const TextStyle(fontFamily: 'Cairo'),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    style: TextStyle(fontFamily: 'Cairo', color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      labelStyle: const TextStyle(fontFamily: 'Cairo'),
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Remember me & Forgot Password Row (Responsive Wrap)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (val) => setState(() => _rememberMe = val ?? true),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            child: Text(
                              'تذكرني على هذا الجهاز',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const PasswordResetDialog(),
                          );
                        },
                        child: const Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'دخول المنصة',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register link (Responsive Wrap)
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'ليس لديك حساب مسؤول بعد؟',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                          );
                        },
                        child: const Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.emerald),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
