import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Modal dialog to trigger secure email password reset without enumerating user existence.
class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({super.key});

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    await auth.requestPasswordReset(_emailCtrl.text);
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('استعادة كلمة المرور', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: _sent
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mark_email_read_outlined, color: AppColors.emerald, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'إذا كان هذا البريد مسجلاً في النظام، فقد تم إرسال تعليمات استعادة الحساب بأمان إليه.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'أدخل بريدك الإلكتروني لإرسال رابط إعادة تعيين كلمة المرور بأمان:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.email, color: AppColors.emerald),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_sent ? 'إغلاق' : 'إلغاء', style: const TextStyle(color: Colors.white70)),
          ),
          if (!_sent)
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('إرسال الرابط', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
