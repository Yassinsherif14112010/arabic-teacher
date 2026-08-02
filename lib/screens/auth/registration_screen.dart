import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth/auth_validator.dart';
import '../../theme/app_theme.dart';

/// Secure Registration screen with real-time Password Strength Meter and complexity warnings.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _strengthScore = 0;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String val) {
    setState(() {
      _strengthScore = AuthValidator.calculatePasswordStrength(val);
    });
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _emailCtrl.text,
      _passwordCtrl.text,
      _confirmCtrl.text,
    );
    if (!success && auth.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (success && mounted) {
      Navigator.of(context).pop(); // Return to Login or let AuthProvider route to AppShell
    }
  }

  Widget _buildStrengthMeter() {
    final colors = [
      AppColors.red,
      Colors.orange,
      AppColors.yellow,
      AppColors.emerald,
    ];
    final labels = [
      'ضعيفة جداً (سهلة الاختراق)',
      'ضعيفة (يرجى إطالتها)',
      'مقبولة (أضف أرقاماً ورموزاً)',
      'جيدة (تفي بالشروط)',
      'قوية جداً ومحمية (Enterprise Grade)',
    ];
    final activeColor = _strengthScore > 0 ? colors[(_strengthScore - 1).clamp(0, 3)] : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final active = index < _strengthScore;
            return Expanded(
              child: AnimatedContainer(
                duration: 250.ms,
                height: 6,
                margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                decoration: BoxDecoration(
                  color: active ? activeColor : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: activeColor),
            const SizedBox(width: 6),
            Text(
              'قوة كلمة المرور: ${labels[_strengthScore.clamp(0, 4)]}',
              style: TextStyle(fontSize: 12, color: activeColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF090D16), Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: size.width > 500 ? 480 : double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Expanded(
                          child: Text(
                            'إنشاء حساب معلم آمن',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.emerald),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: Colors.white),
                      onChanged: _onPasswordChanged,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور (8 أحرف، رموز وأرقام)',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.emerald),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStrengthMeter(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.emerald),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'تأكيد الحساب وتأمينه',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),
            ),
          ),
        ),
      ),
    );
  }
}
