import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../models/student.dart';
import '../models/fee_setting.dart';
import '../models/payment.dart';
import '../theme/app_theme.dart';

/// Shared utility for toggling student monthly fee paid status.
/// Enforces that a monthly fee amount must be configured for the student's grade
/// before marking them as paid, prevents duplicate payment entries in the same month,
/// and automatically deletes the month's payment record if unchecked.
Future<void> toggleStudentFeeStatus(
  BuildContext context,
  AppProvider app,
  Student student,
) async {
  final targetPaidStatus = !student.feePaid;
  final now = DateTime.now();
  final isoDate = now.toIso8601String().substring(0, 10);
  final monthStr = '${now.year}-${now.month.toString().padLeft(2, "0")}';

  if (targetPaidStatus) {
    // Attempt to locate a FeeSetting for this student's grade
    FeeSetting? matchedSetting;
    for (final fs in app.feeSettings) {
      if (fs.grade == student.grade && fs.feeAmount > 0) {
        matchedSetting = fs;
        break;
      }
    }

    if (matchedSetting == null) {
      // Prevent marking as paid and alert the teacher about monthly fees
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'عفواً، يجب تحديد المصاريف الشهرية للصف (${student.grade ?? "غير محدد"}) أولاً من إعدادات الرسوم قبل تسجيل السداد!',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'فهمت',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    // 1) Update student feePaid = true in database & sync
    await app.updateStudent(student.copyWith(feePaid: true));

    // 2) Check if a payment for this student already exists for THIS month
    final existingMonthPayment = app.payments.any(
      (p) => p.studentId == student.id && p.month == monthStr,
    );

    // Only create a payment record if one doesn't exist for the current month
    if (!existingMonthPayment) {
      final payment = Payment(
        studentId: student.id!,
        amount: matchedSetting.feeAmount,
        paymentDate: isoDate,
        paymentMethod: PaymentMethod.cash,
        month: monthStr,
        notes: 'سداد المصاريف الشهرية ($monthStr) للصف (${student.grade}) — مسجل تلقائياً',
      );
      await app.addPayment(payment);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إثبات سداد المصاريف الشهرية (${matchedSetting.feeAmount.toStringAsFixed(0)} ج.م) لشهر ($monthStr) للطالب (${student.name}) بنجاح! ✓',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } else {
    // Revert to unpaid
    await app.updateStudent(student.copyWith(feePaid: false));

    // Automatically remove any payment records created for this student in THIS month
    final monthPaymentsToDelete = app.payments
        .where((p) => p.studentId == student.id && p.month == monthStr)
        .toList();
    for (final p in monthPaymentsToDelete) {
      if (p.id != null) {
        await app.deletePayment(p.id!);
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إلغاء علامة الدفع وحذف دفعة شهر ($monthStr) للطالب (${student.name})',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
