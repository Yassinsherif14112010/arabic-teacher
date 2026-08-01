import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

/// Modal displaying active session status, secure audit logs, and sign-out controls.
class SecuritySettingsDialog extends StatelessWidget {
  const SecuritySettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.emerald, size: 24),
            const SizedBox(width: 8),
            Text(
              'أمن الحساب والسجلات (Enterprise Security)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.emerald, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الحساب النشط: ${auth.currentEmail ?? "مسؤول المنصة الأوفلاين"}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'جلسة مشفرة بأمان عبر flutter_secure_storage (بدون تسريب للتوكن أو الشفرات).',
                            style: TextStyle(fontSize: 11, color: AppColors.emerald),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'سجل نشاط المصادقة (Audit Logs):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: DatabaseService.getAuthLogs(limit: 20),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final logs = snapshot.data ?? [];
                    if (logs.isEmpty) {
                      return Center(
                        child: Text('لا توجد تسجلات مصادقة مسبقة.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                      );
                    }
                    return ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                      itemBuilder: (context, index) {
                        final item = logs[index];
                        final type = item['eventType'] ?? 'event';
                        final msg = item['message'] ?? '';
                        final time = item['timestamp']?.toString().split('.').first ?? '';
                        
                        IconData icon;
                        Color iconColor;
                        if (type == 'login_success' || type == 'session_restored') {
                          icon = Icons.login;
                          iconColor = AppColors.emerald;
                        } else if (type == 'login_failed' || type == 'lockout_triggered') {
                          icon = Icons.warning_amber_rounded;
                          iconColor = AppColors.red;
                        } else {
                          icon = Icons.security;
                          iconColor = AppColors.primary;
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          leading: Icon(icon, color: iconColor, size: 20),
                          title: Text(msg, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
                          subtitle: Text('$type • $time', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await auth.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            icon: const Icon(Icons.logout, color: Colors.white, size: 18),
            label: const Text('تسجيل الخروج من كل الأجهزة', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إغلاق', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          ),
        ],
      ),
    );
  }
}
