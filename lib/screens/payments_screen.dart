import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/payment.dart';
import '../models/fee_setting.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/confirm_dialog.dart';
import 'students_screen.dart' show kGrades;
import '../models/student.dart';
import '../widgets/fee_payment_helper.dart';

/// Payments screen — fee settings, payment records, filtering.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  int _selectedView = 0; // 0 = السداد السريع للطلاب, 1 = سجل الدفعات التفصيلي
  bool _showFeeSettings = false;
  bool _showAddForm = false;
  String _filterMonth = '';
  int? _filterStudentId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);

    final contentWidth = ContentWidthProvider.of(context);
    final isTablet = contentWidth >= 480;
    final padding = isTablet ? 20.0 : 16.0;

    // Filter payments
    final filtered = app.payments.where((p) {
      final matchMonth =
          _filterMonth.isEmpty || (p.month?.startsWith(_filterMonth) ?? false);
      final matchStudent =
          _filterStudentId == null || p.studentId == _filterStudentId;
      return matchMonth && matchStudent;
    }).toList();

    final total = filtered.fold<double>(0, (sum, p) => sum + p.amount);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.payments_rounded,
                    color: AppColors.orange, size: 26),
                const SizedBox(width: 12),
                Text('إدارة المصروفات والدفعات',
                    style: theme.textTheme.headlineMedium),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _showFeeSettings = !_showFeeSettings),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('المصاريف الشهرية'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _showAddForm = !_showAddForm),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('تسجيل دفعة'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Fee settings panel ───────────────────────────────────────
            if (_showFeeSettings) ...[
              _FeeSettingsPanel(app: app),
              const SizedBox(height: 16),
            ],

            // ── Add payment form ─────────────────────────────────────────
            if (_showAddForm) ...[
              _AddPaymentForm(
                app: app,
                onDone: () => setState(() => _showAddForm = false),
              ),
              const SizedBox(height: 16),
            ],

            // ── Stats ────────────────────────────────────────────────────
            if (isTablet)
              Row(
                children: [
                  Expanded(
                      child: _StatCard(
                          label: 'إجمالي الطلاب',
                          value: '${app.students.length}',
                          icon: Icons.people_outline,
                          color: theme.colorScheme.primary)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _StatCard(
                          label: 'عدد الدفعات',
                          value: '${filtered.length}',
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.orange)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _StatCard(
                          label: 'إجمالي المبلغ',
                          value: '${total.toStringAsFixed(2)} ج.م',
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppColors.emerald)),
                ],
              )
            else
              Column(
                children: [
                  _StatCard(
                      label: 'إجمالي الطلاب',
                      value: '${app.students.length}',
                      icon: Icons.people_outline,
                      color: theme.colorScheme.primary),
                  const SizedBox(height: 10),
                  _StatCard(
                      label: 'عدد الدفعات',
                      value: '${filtered.length}',
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.orange),
                  const SizedBox(height: 10),
                  _StatCard(
                      label: 'إجمالي المبلغ',
                      value: '${total.toStringAsFixed(2)} ج.م',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.emerald),
                ],
              ),
            const SizedBox(height: 20),

            // ── View Switcher ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _ViewSwitchTab(
                      label: 'السداد السريع لكل صف (بنقرة واحدة)',
                      icon: Icons.check_circle_outline,
                      isSelected: _selectedView == 0,
                      onTap: () => setState(() => _selectedView = 0),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _ViewSwitchTab(
                      label: 'سجل الفواتير والدفعات السابقة',
                      icon: Icons.history,
                      isSelected: _selectedView == 1,
                      onTap: () => setState(() => _selectedView = 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Content depending on selected view ───────────────────────
            if (_selectedView == 0)
              _QuickGradePaymentsSection(
                app: app,
                onOpenSettings: () {
                  setState(() => _showFeeSettings = true);
                },
              )
            else ...[
              // ── Filters ──────────────────────────────────────────────────
              if (isTablet)
                Row(
                  children: [
                    Expanded(child: _buildStudentFilter(app, theme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMonthFilter(theme)),
                  ],
                )
              else ...[
                _buildStudentFilter(app, theme),
                const SizedBox(height: 10),
                _buildMonthFilter(theme),
              ],
              const SizedBox(height: 20),

              // ── Payments table ───────────────────────────────────────────
              filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.payments_outlined,
                      message: 'لا توجد دفعات مسجلة',
                    )
                  : _PaymentsTable(
                      payments: filtered,
                      app: app,
                      isTablet: isTablet,
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentFilter(AppProvider app, ThemeData theme) {
    return DropdownButtonFormField<int?>(
      isExpanded: true,
      initialValue: _filterStudentId,
      decoration: const InputDecoration(labelText: 'تصفية بالطالب'),
      items: [
        const DropdownMenuItem(value: null, child: Text('كل الطلاب', overflow: TextOverflow.ellipsis)),
        ...app.students.map((s) =>
            DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (v) => setState(() => _filterStudentId = v),
    );
  }

  Widget _buildMonthFilter(ThemeData theme) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'تصفية بالشهر (yyyy-MM)',
        hintText: 'مثال: 2025-01',
        prefixIcon: Icon(Icons.calendar_month_outlined),
      ),
      onChanged: (v) => setState(() => _filterMonth = v.trim()),
    );
  }
}

// ─── Fee settings panel ───────────────────────────────────────────────────────

class _FeeSettingsPanel extends StatefulWidget {
  final AppProvider app;

  const _FeeSettingsPanel({required this.app});

  @override
  State<_FeeSettingsPanel> createState() => _FeeSettingsPanelState();
}

class _FeeSettingsPanelState extends State<_FeeSettingsPanel> {
  String _grade = kGrades.first;
  late final TextEditingController _yearCtrl;
  final _amountCtrl = TextEditingController();

  static String _currentAcademicYear() {
    final now = DateTime.now();
    final y = now.year;
    return now.month >= 10 ? '$y-${y + 1}' : '${y - 1}-$y';
  }

  @override
  void initState() {
    super.initState();
    _yearCtrl = TextEditingController(text: _currentAcademicYear());
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = widget.app;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.orange.withAlpha(77)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_outlined,
                    color: AppColors.orange, size: 20),
                const SizedBox(width: 8),
                Text('إعداد قيمة المصاريف الشهرية لكل صف',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.orange)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 160,
                  child: TextField(
                    decoration: const InputDecoration(
                        labelText: 'الفترة / العام'),
                    controller: _yearCtrl,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _grade,
                    decoration: const InputDecoration(labelText: 'الصف'),
                    items: kGrades
                        .map((g) =>
                            DropdownMenuItem(value: g, child: Text(g, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _grade = v!),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'المبلغ (ج.م)'),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final amount =
                        double.tryParse(_amountCtrl.text.trim()) ?? 0;
                    if (amount <= 0) return;
                    await app.upsertFeeSetting(FeeSetting(
                      academicYear: _yearCtrl.text.trim(),
                      grade: _grade,
                      feeAmount: amount,
                    ));
                    _amountCtrl.clear();
                  },
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('حفظ'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange),
                ),
              ],
            ),
            if (app.feeSettings.isNotEmpty) ...[
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('الفترة / العام')),
                    DataColumn(label: Text('الصف')),
                    DataColumn(label: Text('المبلغ')),
                    DataColumn(label: Text('')),
                  ],
                  rows: app.feeSettings.map((fs) {
                    return DataRow(cells: [
                      DataCell(Text(fs.academicYear)),
                      DataCell(Text(fs.grade)),
                      DataCell(Text(
                          '${fs.feeAmount.toStringAsFixed(0)} ج.م')),
                      DataCell(IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: theme.colorScheme.error, size: 18),
                        onPressed: () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            title: 'حذف الرسوم',
                            message: 'هل تريد حذف هذا الإعداد؟',
                            confirmLabel: 'حذف',
                          );
                          if (confirmed && context.mounted) {
                            await app.deleteFeeSetting(fs.id!);
                          }
                        },
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Add payment form ─────────────────────────────────────────────────────────

class _AddPaymentForm extends StatefulWidget {
  final AppProvider app;
  final VoidCallback onDone;

  const _AddPaymentForm({required this.app, required this.onDone});

  @override
  State<_AddPaymentForm> createState() => _AddPaymentFormState();
}

class _AddPaymentFormState extends State<_AddPaymentForm> {
  int? _studentId;
  final _amountCtrl = TextEditingController();
  late final TextEditingController _dateCtrl;
  PaymentMethod _method = PaymentMethod.cash;
  late final TextEditingController _monthCtrl;
  final _notesCtrl = TextEditingController();

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _dateCtrl = TextEditingController(text: _todayStr());
    _monthCtrl = TextEditingController(text: _currentMonth());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _monthCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = widget.app;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('تسجيل دفعة جديدة',
                    style: theme.textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onDone,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: _studentId,
                    decoration:
                        const InputDecoration(labelText: 'الطالب *'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('اختر الطالب', overflow: TextOverflow.ellipsis)),
                      ...app.students.map((s) => DropdownMenuItem(
                          value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _studentId = v),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'المبلغ (ج.م) *'),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    decoration: const InputDecoration(
                        labelText: 'تاريخ الدفع (yyyy-MM-dd)'),
                    controller: _dateCtrl,
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<PaymentMethod>(
                    isExpanded: true,
                    initialValue: _method,
                    decoration:
                        const InputDecoration(labelText: 'طريقة الدفع'),
                    items: PaymentMethod.values
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text(m.label, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    decoration: const InputDecoration(
                        labelText: 'الشهر (yyyy-MM)'),
                    controller: _monthCtrl,
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_studentId == null) return;
                    final amount =
                        double.tryParse(_amountCtrl.text.trim()) ?? 0;
                    if (amount <= 0) return;
                    final month = _monthCtrl.text.trim();
                    await app.addPayment(Payment(
                      studentId: _studentId!,
                      amount: amount,
                      paymentDate: _dateCtrl.text.trim(),
                      paymentMethod: _method,
                      month: month.isEmpty ? null : month,
                      notes: _notesCtrl.text.trim().isEmpty
                          ? null
                          : _notesCtrl.text.trim(),
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('✅ تم تسجيل الدفعة بنجاح!')),
                      );
                      widget.onDone();
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('تسجيل الدفعة'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: widget.onDone,
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Payments table ───────────────────────────────────────────────────────────

class _PaymentsTable extends StatelessWidget {
  final List<Payment> payments;
  final AppProvider app;
  final bool isTablet;

  const _PaymentsTable({
    required this.payments,
    required this.app,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String studentName(int id) {
      try {
        return app.students.firstWhere((s) => s.id == id).name;
      } catch (_) {
        return 'غير معروف';
      }
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
              theme.colorScheme.surface),
          columns: [
            const DataColumn(label: Text('الطالب')),
            const DataColumn(label: Text('المبلغ')),
            if (isTablet) ...[
              const DataColumn(label: Text('التاريخ')),
              const DataColumn(label: Text('الطريقة')),
              const DataColumn(label: Text('الشهر')),
            ],
            const DataColumn(label: Text('ملاحظات')),
            const DataColumn(label: Text('')),
          ],
          rows: payments.map((p) {
            return DataRow(cells: [
              DataCell(Text(studentName(p.studentId))),
              DataCell(Text(
                '${p.amount.toStringAsFixed(2)} ج.م',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: AppColors.emerald,
                ),
              )),
              if (isTablet) ...[
                DataCell(Text(p.paymentDate)),
                DataCell(_MethodBadge(method: p.paymentMethod)),
                DataCell(Text(p.month ?? '—')),
              ],
              DataCell(Text(p.notes ?? '—')),
              DataCell(IconButton(
                icon: Icon(Icons.delete_outline,
                    color: theme.colorScheme.error, size: 18),
                onPressed: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'حذف الدفعة',
                    message: 'هل تريد حذف هذه الدفعة؟',
                    confirmLabel: 'حذف',
                  );
                  if (confirmed && context.mounted) {
                    await context.read<AppProvider>().deletePayment(p.id!);
                  }
                },
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final PaymentMethod method;

  const _MethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    final color = method == PaymentMethod.cash
        ? AppColors.emerald
        : method == PaymentMethod.transfer
            ? AppColors.primary
            : AppColors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        method.label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── View Switcher Tab ────────────────────────────────────────────────────────

class _ViewSwitchTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewSwitchTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? AppColors.orange : theme.colorScheme.onSurface.withAlpha(150);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.orange : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Grade Payments Section ──────────────────────────────────────────────

class _QuickGradePaymentsSection extends StatelessWidget {
  final AppProvider app;
  final VoidCallback onOpenSettings;

  const _QuickGradePaymentsSection({
    required this.app,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    if (app.students.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        message: 'لا يوجد طلاب مسجلون لعرض قائمة سداد الرسوم.',
      );
    }

    // Group students by grade
    final byGrade = <String, List<Student>>{};
    for (final s in app.students) {
      final g = s.grade ?? 'بدون صف';
      byGrade.putIfAbsent(g, () => []).add(s);
    }

    final gradeOrder = [
      ...kGrades.where((g) => byGrade.containsKey(g)),
      if (byGrade.containsKey('بدون صف')) 'بدون صف',
      ...byGrade.keys.where((k) => !kGrades.contains(k) && k != 'بدون صف'),
    ];

    return Column(
      children: gradeOrder.map((grade) {
        final gradeStudents = byGrade[grade]!..sort((a, b) => a.name.compareTo(b.name));
        FeeSetting? feeSetting;
        for (final fs in app.feeSettings) {
          if (fs.grade == grade && fs.feeAmount > 0) {
            feeSetting = fs;
            break;
          }
        }
        return _GradePaymentsCard(
          grade: grade,
          students: gradeStudents,
          feeSetting: feeSetting,
          app: app,
          onOpenSettings: onOpenSettings,
        );
      }).toList(),
    );
  }
}

class _GradePaymentsCard extends StatelessWidget {
  final String grade;
  final List<Student> students;
  final FeeSetting? feeSetting;
  final AppProvider app;
  final VoidCallback onOpenSettings;

  const _GradePaymentsCard({
    required this.grade,
    required this.students,
    required this.feeSetting,
    required this.app,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paidCount = students.where((s) => s.feePaid).length;
    final unpaidCount = students.length - paidCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Column(
          children: [
            // Grade header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.orange.withAlpha(26),
                    AppColors.orange.withAlpha(13),
                  ],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: const Border(
                  right: BorderSide(color: AppColors.orange, width: 4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(grade, style: theme.textTheme.titleMedium),
                        const SizedBox(width: 8),
                        Text('(${students.length} طالب)', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  // Fee amount indicator or warning
                  GestureDetector(
                    onTap: feeSetting == null ? onOpenSettings : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (feeSetting != null ? AppColors.emerald : AppColors.red).withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: feeSetting != null ? AppColors.emerald : AppColors.red),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            feeSetting != null ? Icons.payments : Icons.warning_amber_rounded,
                            size: 15,
                            color: feeSetting != null ? AppColors.emerald : AppColors.red,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            feeSetting != null
                                ? 'المصاريف الشهرية: ${feeSetting!.feeAmount.toStringAsFixed(0)} ج.م'
                                : '⚠️ لم تحدد المصاريف الشهرية للصف (اضغط للتحديد)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: feeSetting != null ? AppColors.emerald : AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MiniPayStat(count: paidCount, label: 'دفع:', color: AppColors.emerald),
                  const SizedBox(width: 6),
                  _MiniPayStat(count: unpaidCount, label: 'لم يدفع:', color: AppColors.red),
                ],
              ),
            ),

            // Student rows
            ...students.asMap().entries.map((entry) {
              final idx = entry.key;
              final student = entry.value;
              return _PaymentStudentRow(
                index: idx + 1,
                student: student,
                app: app,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MiniPayStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _MiniPayStat({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _PaymentStudentRow extends StatelessWidget {
  final int index;
  final Student student;
  final AppProvider app;

  const _PaymentStudentRow({
    required this.index,
    required this.student,
    required this.app,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaid = student.feePaid;

    return Container(
      color: isPaid ? AppColors.emerald.withAlpha(13) : AppColors.red.withAlpha(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Index avatar
          SizedBox(
            width: 36,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary.withAlpha(26),
              child: Text(
                '$index',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name & Barcode
          Expanded(
            child: Row(
              children: [
                Text(
                  student.name,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 10),
                Text(
                  '#${student.barcodeNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (isPaid ? AppColors.emerald : AppColors.red).withAlpha(40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (isPaid ? AppColors.emerald : AppColors.red).withAlpha(100)),
            ),
            child: Text(
              isPaid ? 'مدفوعة ✓' : 'غير مدفوعة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isPaid ? AppColors.emerald : AppColors.red,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Action Button (Identical style to Attendance Quick Buttons)
          Tooltip(
            message: isPaid ? 'اضغط لإلغاء السداد' : 'اضغط لتسجيل السداد فوراً',
            child: GestureDetector(
              onTap: () => toggleStudentFeeStatus(context, app, student),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.emerald : AppColors.orange.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isPaid ? AppColors.emerald : AppColors.orange),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle : Icons.payment,
                      color: isPaid ? Colors.white : AppColors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPaid ? 'مسجل كدفع' : 'تأكيد الدفع',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? Colors.white : AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

