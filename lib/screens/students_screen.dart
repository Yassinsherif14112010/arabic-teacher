import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../providers/app_provider.dart';
import '../models/student.dart';
import '../models/study_group.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/motion/staggered_list_item.dart';
import '../services/print_service.dart';
import '../widgets/fee_payment_helper.dart';

const List<String> kGrades = [
  'الصف الأول الإعدادي',
  'الصف الثاني الإعدادي',
  'الصف الثالث الإعدادي',
  'الصف الأول الثانوي',
  'الصف الثاني الثانوي',
  'الصف الثالث الثانوي',
];

/// Students management screen — CRUD, barcode display, grade grouping.
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _search = '';
  Student? _selectedStudent; // for barcode card modal

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final contentWidth = ContentWidthProvider.of(context);
    final isTablet = contentWidth >= 480;

    // Filter
    final filtered = app.students.where((s) {
      final q = _search.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.barcodeNumber.contains(q);
    }).toList();

    // Group by grade
    final Map<String, List<Student>> byGrade = {};
    for (final s in filtered) {
      final g = s.grade ?? 'بدون صف';
      byGrade.putIfAbsent(g, () => []).add(s);
    }
    final gradeOrder = [
      ...kGrades.where(byGrade.containsKey),
      ...byGrade.keys.where((k) => !kGrades.contains(k)),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────────
              _buildTopBar(context, app, theme, isTablet),

              // ── Search ──────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 16, vertical: 12),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن طالب أو باركود...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _search = ''),
                          )
                        : null,
                  ),
                ),
              ),

              // ── Student list ─────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        message: _search.isEmpty
                            ? 'لا يوجد طلاب مسجلون'
                            : 'لا توجد نتائج للبحث',
                        actionLabel:
                            _search.isEmpty ? 'إضافة طالب' : null,
                        onAction: _search.isEmpty
                            ? () => _showStudentDialog(context, app)
                            : null,
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 24 : 16),
                        itemCount: gradeOrder.length,
                        itemBuilder: (context, gi) {
                          final grade = gradeOrder[gi];
                          final gradeStudents = byGrade[grade]!;
                          return StaggeredListItem(
                            index: gi,
                            child: _GradeSection(
                              grade: grade,
                              students: gradeStudents,
                              app: app,
                              isTablet: isTablet,
                              onViewCard: (s) =>
                                  setState(() => _selectedStudent = s),
                              onEdit: (s) =>
                                  _showStudentDialog(context, app, existing: s),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // ── Barcode card overlay ─────────────────────────────────────────
          if (_selectedStudent != null)
            _BarcodeCardOverlay(
              student: _selectedStudent!,
              onClose: () => setState(() => _selectedStudent = null),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppProvider app, ThemeData theme,
      bool isTablet) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          isTablet ? 24 : 16, isTablet ? 20 : 16, isTablet ? 24 : 16, 0),
      child: Row(
        children: [
          Icon(Icons.people_rounded,
              color: theme.colorScheme.primary, size: 26),
          const SizedBox(width: 12),
          Text('إدارة الطلاب', style: theme.textTheme.headlineMedium),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${app.students.length} طالب',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showStudentDialog(context, app),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة طالب'),
          ),
        ],
      ),
    );
  }

  // ─── Add / Edit dialog ────────────────────────────────────────────────────

  void _showStudentDialog(BuildContext context, AppProvider app,
      {Student? existing}) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final phoneCtrl =
        TextEditingController(text: existing?.phone ?? '');
    final parentPhoneCtrl =
        TextEditingController(text: existing?.parentPhone ?? '');
    String? selectedGrade = existing?.grade;
    int? selectedGroupId = existing?.groupId;
    bool feePaid = existing?.feePaid ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final groupsForGrade = selectedGrade != null
              ? app.groupsForGrade(selectedGrade!)
              : <StudyGroup>[];

          return AlertDialog(
            title: Text(
                existing == null ? 'إضافة طالب جديد' : 'تعديل بيانات الطالب'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'اسم الطالب *'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'رقم الطالب'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: parentPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'رقم ولي الأمر'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      value: selectedGrade,
                      decoration:
                          const InputDecoration(labelText: 'الصف الدراسي'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('اختر الصف', overflow: TextOverflow.ellipsis)),
                        ...kGrades.map((g) =>
                            DropdownMenuItem(value: g, child: Text(g, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (v) => setDialogState(() {
                        selectedGrade = v;
                        selectedGroupId = null;
                      }),
                    ),
                    if (selectedGrade != null) ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int?>(
                        isExpanded: true,
                        value: selectedGroupId,
                        decoration: const InputDecoration(
                            labelText: 'المجموعة الدراسية'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('بدون مجموعة', overflow: TextOverflow.ellipsis)),
                          ...groupsForGrade.map((g) => DropdownMenuItem(
                              value: g.id, child: Text(g.name, overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedGroupId = v),
                      ),
                    ],
                    const SizedBox(height: 14),
                    CheckboxListTile(
                      value: feePaid,
                      onChanged: (v) =>
                          setDialogState(() => feePaid = v ?? false),
                      title: const Text('دفع المصاريف'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final student = Student(
                    id: existing?.id,
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty
                        ? null
                        : phoneCtrl.text.trim(),
                    parentPhone: parentPhoneCtrl.text.trim().isEmpty
                        ? null
                        : parentPhoneCtrl.text.trim(),
                    barcodeNumber: existing?.barcodeNumber ??
                        app.generateBarcode(),
                    grade: selectedGrade,
                    groupId: selectedGroupId,
                    feePaid: feePaid,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (existing == null) {
                    await app.addStudent(student);
                  } else {
                    await app.updateStudent(student);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Grade section ────────────────────────────────────────────────────────────

class _GradeSection extends StatelessWidget {
  final String grade;
  final List<Student> students;
  final AppProvider app;
  final bool isTablet;
  final ValueChanged<Student> onViewCard;
  final ValueChanged<Student> onEdit;

  const _GradeSection({
    required this.grade,
    required this.students,
    required this.app,
    required this.isTablet,
    required this.onViewCard,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paid = students.where((s) => s.feePaid).length;
    final unpaid = students.length - paid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grade header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(13),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                border: Border(
                  right: BorderSide(
                      color: theme.colorScheme.primary, width: 4),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    Text(grade, style: theme.textTheme.titleMedium),
                    const SizedBox(width: 16),
                    _Pill(
                        label: 'دفع: $paid',
                        color: AppColors.emerald),
                    const SizedBox(width: 8),
                    _Pill(
                        label: 'لم يدفع: $unpaid',
                        color: AppColors.red),
                    const SizedBox(width: 8),
                    _Pill(
                        label: '${students.length} طالب',
                        color: AppColors.primary),
                  ],
                ),
              ),
            ),

            // Student rows
            ...students.asMap().entries.map((entry) {
              final idx = entry.key;
              final student = entry.value;
              return StaggeredListItem(
                index: idx,
                child: _StudentRow(
                  index: idx + 1,
                  student: student,
                  app: app,
                  isTablet: isTablet,
                  onViewCard: () => onViewCard(student),
                  onEdit: () => onEdit(student),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final int index;
  final Student student;
  final AppProvider app;
  final bool isTablet;
  final VoidCallback onViewCard;
  final VoidCallback onEdit;

  const _StudentRow({
    required this.index,
    required this.student,
    required this.app,
    required this.isTablet,
    required this.onViewCard,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Index
            SizedBox(
              width: 32,
              child: Text(
                '$index',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            // Name
            Expanded(
              flex: 3,
              child: Text(
                student.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),

            // Barcode (tablet only)
            if (isTablet) ...[
              Expanded(
                flex: 2,
                child: Text(
                  student.barcodeNumber,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],

            // Study Group Selector Dropdown
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: app.groups
                            .where((g) => g.grade == (student.grade ?? ''))
                            .any((g) => g.id == student.groupId)
                        ? student.groupId
                        : null,
                    isExpanded: true,
                    icon: Icon(Icons.group_work_outlined, size: 16, color: theme.colorScheme.primary),
                    hint: Text(
                      'اختر مجموعة...',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: theme.colorScheme.primary),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'بدون مجموعة',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...app.groups
                          .where((g) => g.grade == (student.grade ?? ''))
                          .map((g) => DropdownMenuItem<int?>(
                                value: g.id,
                                child: Text(
                                  g.name,
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                    ],
                    onChanged: (newGroupId) async {
                      await app.updateStudent(student.copyWith(groupId: newGroupId));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم تغيير مجموعة الطالب (${student.name}) بنجاح ✓',
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: AppColors.emerald,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),

            // Fee status toggle
            GestureDetector(
              onTap: () => toggleStudentFeeStatus(context, app, student),
              child: Icon(
                student.feePaid
                    ? Icons.check_circle
                    : Icons.cancel_outlined,
                color: student.feePaid ? AppColors.emerald : AppColors.red,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                  icon: Icons.badge_outlined,
                  color: theme.colorScheme.primary,
                  tooltip: 'عرض البطاقة',
                  onTap: onViewCard,
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  color: AppColors.orange,
                  tooltip: 'تعديل',
                  onTap: onEdit,
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: Icons.delete_outline,
                  color: AppColors.red,
                  tooltip: 'حذف',
                  onTap: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'حذف الطالب',
                      message:
                          'هل أنت متأكد من حذف "${student.name}"؟',
                      confirmLabel: 'حذف',
                    );
                    if (confirmed && context.mounted) {
                      await app.deleteStudent(student.id!);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
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

// ─── Barcode card overlay ─────────────────────────────────────────────────────

class _BarcodeCardOverlay extends StatelessWidget {
  final Student student;
  final VoidCallback onClose;

  const _BarcodeCardOverlay(
      {required this.student, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent close on card tap
            child: Card(
              margin: const EdgeInsets.all(32),
              child: SizedBox(
                width: 360,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الشاعر في اللغة العربية',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'أ. محسن شاكر',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: onClose,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: theme.dividerColor),
                      const SizedBox(height: 16),

                      // Student info
                      _CardRow(label: 'الاسم', value: student.name),
                      const SizedBox(height: 8),
                      _CardRow(
                          label: 'الصف',
                          value: student.grade ?? '—'),
                      const SizedBox(height: 8),
                      _CardRow(
                          label: 'الباركود',
                          value: student.barcodeNumber),
                      const SizedBox(height: 8),
                      _CardRow(
                        label: 'المصاريف',
                        value: student.feePaid ? 'مدفوعة ✓' : 'غير مدفوعة',
                        valueColor: student.feePaid
                            ? AppColors.emerald
                            : AppColors.red,
                      ),
                      const SizedBox(height: 20),

                      // Barcode inside white rectangle for maximum scanner contrast
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Colors.grey.shade300, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: student.barcodeNumber,
                            width: 250,
                            height: 75,
                            drawText: true,
                            color: Colors.black,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Print and Close buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                PrintService.printStudentCard(
                                  student.name,
                                  student.grade ?? '—',
                                  student.barcodeNumber,
                                );
                              },
                              icon: const Icon(Icons.print_outlined, size: 20),
                              label: const Text('طباعة الباركود'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              onPressed: onClose,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('إغلاق',
                                  style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CardRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall,
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
