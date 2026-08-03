import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/attendance.dart';
import '../models/student.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width_provider.dart';
import '../widgets/empty_state.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'students_screen.dart' show kGrades;
import '../widgets/motion/shimmer_loading.dart';
import '../services/attendance_report_service.dart';

/// Attendance screen — barcode scan, roll-number entry, manual per-student.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _selectedDate = _todayStr();
  final _barcodeCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  String _rollGrade = kGrades.first;

  // Local status overrides (optimistic UI)
  final Map<int, AttendanceStatus> _localStatus = {};

  // Expandable stat cards
  AttendanceStatus? _expandedStat;

  // Attendance records for selected date (loaded on demand)
  bool _loadingRecords = false;

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecords());
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _rollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _loadingRecords = true);
    try {
      final app = context.read<AppProvider>();
      final records = await app.getAttendanceForDate(_selectedDate);
      if (mounted) {
        setState(() {
          _localStatus.clear();
          for (final r in records) {
            _localStatus[r.studentId] = r.status;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading attendance records: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingRecords = false);
      }
    }
  }

  AttendanceStatus? _statusFor(int studentId) => _localStatus[studentId];

  Future<void> _record(int studentId, AttendanceStatus status) async {
    setState(() => _localStatus[studentId] = status);
    final app = context.read<AppProvider>();
    await app.recordAttendance(
      studentId: studentId,
      date: _selectedDate,
      status: status,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل ${status.label}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleBarcodeSubmit() {
    final barcode = _barcodeCtrl.text.trim();
    if (barcode.isEmpty) return;
    final app = context.read<AppProvider>();
    final student = app.findStudentByBarcode(barcode);
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على الطالب')),
      );
    } else {
      _record(student.id!, AttendanceStatus.present);
    }
    _barcodeCtrl.clear();
  }

  void _handleRollSubmit() {
    final rollStr = _rollCtrl.text.trim();
    if (rollStr.isEmpty) return;
    final rollNum = int.tryParse(rollStr);
    if (rollNum == null || rollNum < 1) return;

    final app = context.read<AppProvider>();
    final gradeStudents = app.students
        .where((s) => (s.grade ?? 'بدون صف') == _rollGrade)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (rollNum > gradeStudents.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الكشف غير موجود في هذا الصف')),
      );
      return;
    }
    final student = gradeStudents[rollNum - 1];
    _record(student.id!, AttendanceStatus.present);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تسجيل حضور: ${student.name}')),
    );
    _rollCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final contentWidth = ContentWidthProvider.of(context);
    final isTablet = contentWidth >= 480;
    final padding = isTablet ? 20.0 : 16.0;

    final students = app.students;
    final presentList =
        students.where((s) => _statusFor(s.id!) == AttendanceStatus.present).toList();
    final lateList =
        students.where((s) => _statusFor(s.id!) == AttendanceStatus.late).toList();
    final absentList = students
        .where((s) =>
            _statusFor(s.id!) == null ||
            _statusFor(s.id!) == AttendanceStatus.absent)
        .toList();

    // Group students by grade
    final Map<String, List<Student>> byGrade = {};
    for (final s in students) {
      final g = s.grade ?? 'بدون صف';
      byGrade.putIfAbsent(g, () => []).add(s);
    }
    final gradeOrder = [
      ...kGrades.where(byGrade.containsKey),
      ...byGrade.keys.where((k) => !kGrades.contains(k)),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loadingRecords
          ? const Center(child: ShimmerLoading(width: 320, height: 160, borderRadius: 16))
          : SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.emerald, size: 26),
                      const SizedBox(width: 12),
                      Text('تسجيل الحضور والغياب',
                          style: theme.textTheme.headlineMedium),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final allRecs = await app.getAllAttendance();
                          final monthStr = _selectedDate.length >= 7
                              ? _selectedDate.substring(0, 7)
                              : '2026-08';
                          AttendanceReportService.openMonthlyReport(
                            monthStr,
                            app.students,
                            allRecs,
                            app.groups,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('تقرير الحضور الشهري'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Date picker
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.tryParse(_selectedDate) ??
                                DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 1)),
                            locale: const Locale('ar', 'EG'),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate =
                                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                            });
                            await _loadRecords();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(_selectedDate,
                                  style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Quick entry cards ──────────────────────────────────
                  if (isTablet)
                    Row(
                      children: [
                        Expanded(
                            child: _BarcodeCard(
                                ctrl: _barcodeCtrl,
                                onSubmit: _handleBarcodeSubmit)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _RollCard(
                          ctrl: _rollCtrl,
                          grade: _rollGrade,
                          onGradeChanged: (g) =>
                              setState(() => _rollGrade = g),
                          onSubmit: _handleRollSubmit,
                        )),
                      ],
                    )
                  else ...[
                    _BarcodeCard(
                        ctrl: _barcodeCtrl,
                        onSubmit: _handleBarcodeSubmit),
                    const SizedBox(height: 12),
                    _RollCard(
                      ctrl: _rollCtrl,
                      grade: _rollGrade,
                      onGradeChanged: (g) =>
                          setState(() => _rollGrade = g),
                      onSubmit: _handleRollSubmit,
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Stats row ──────────────────────────────────────────
                  Row(
                    children: [
                      _StatPill(
                        label: 'الإجمالي',
                        count: students.length,
                        color: theme.colorScheme.primary,
                        isExpanded: false,
                        onTap: null,
                      ),
                      const SizedBox(width: 10),
                      _StatPill(
                        label: 'حاضر',
                        count: presentList.length,
                        color: AppColors.emerald,
                        isExpanded: _expandedStat == AttendanceStatus.present,
                        onTap: () => setState(() => _expandedStat =
                            _expandedStat == AttendanceStatus.present
                                ? null
                                : AttendanceStatus.present),
                      ),
                      const SizedBox(width: 10),
                      _StatPill(
                        label: 'غائب',
                        count: absentList.length,
                        color: AppColors.red,
                        isExpanded: _expandedStat == AttendanceStatus.absent,
                        onTap: () => setState(() => _expandedStat =
                            _expandedStat == AttendanceStatus.absent
                                ? null
                                : AttendanceStatus.absent),
                      ),
                      const SizedBox(width: 10),
                      _StatPill(
                        label: 'متأخر',
                        count: lateList.length,
                        color: AppColors.yellow,
                        isExpanded: _expandedStat == AttendanceStatus.late,
                        onTap: () => setState(() => _expandedStat =
                            _expandedStat == AttendanceStatus.late
                                ? null
                                : AttendanceStatus.late),
                      ),
                    ],
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),

                  // Expanded stat list
                  if (_expandedStat != null) ...[
                    const SizedBox(height: 12),
                    _ExpandedStatList(
                      status: _expandedStat!,
                      students: _expandedStat == AttendanceStatus.present
                          ? presentList
                          : _expandedStat == AttendanceStatus.late
                              ? lateList
                              : absentList,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Grade containers ───────────────────────────────────
                  if (students.isEmpty)
                    const EmptyState(
                      icon: Icons.people_outline,
                      message:
                          'لا يوجد طلاب مسجلون. أضف طلاباً من صفحة إدارة الطلاب أولاً.',
                    )
                  else
                    ...gradeOrder.map((grade) {
                      final gradeStudents = byGrade[grade]!
                        ..sort((a, b) => a.name.compareTo(b.name));
                      return _GradeAttendanceCard(
                        grade: grade,
                        students: gradeStudents,
                        statusFor: _statusFor,
                        onRecord: _record,
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

// ─── Barcode entry card ───────────────────────────────────────────────────────

class _BarcodeCard extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSubmit;

  const _BarcodeCard({required this.ctrl, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_scanner,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('تسجيل الحضور بالباركود',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    autofocus: false,
                    onSubmitted: (_) => onSubmit(),
                    decoration: const InputDecoration(
                      hintText: 'امسح الباركود...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onSubmit,
                  child: const Text('تسجيل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Roll number entry card ───────────────────────────────────────────────────

class _RollCard extends StatelessWidget {
  final TextEditingController ctrl;
  final String grade;
  final ValueChanged<String> onGradeChanged;
  final VoidCallback onSubmit;

  const _RollCard({
    required this.ctrl,
    required this.grade,
    required this.onGradeChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_list_numbered,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('تسجيل الحضور برقم الكشف',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: grade,
                    decoration:
                        const InputDecoration(hintText: 'اختر الصف...'),
                    items: kGrades
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(
                                g,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => onGradeChanged(v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => onSubmit(),
                    decoration: const InputDecoration(hintText: 'الرقم'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald),
                  child: const Text('تسجيل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat pill ────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isExpanded;
  final VoidCallback? onTap;

  const _StatPill({
    required this.label,
    required this.count,
    required this.color,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isExpanded ? color.withAlpha(51) : color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExpanded ? color : color.withAlpha(77),
              width: isExpanded ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onTap != null)
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: color,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Expanded stat list ───────────────────────────────────────────────────────

class _ExpandedStatList extends StatelessWidget {
  final AttendanceStatus status;
  final List<Student> students;

  const _ExpandedStatList(
      {required this.status, required this.students});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = status == AttendanceStatus.present
        ? AppColors.emerald
        : status == AttendanceStatus.late
            ? AppColors.yellow
            : AppColors.red;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(77)),
      ),
      child: students.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'لا يوجد ${status.label}ون بعد',
                style: theme.textTheme.bodySmall,
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: students.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (context, i) {
                final s = students[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withAlpha(51),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  title: Text(s.name, style: theme.textTheme.bodyMedium),
                  trailing: s.grade != null
                      ? Text(s.grade!,
                          style: theme.textTheme.bodySmall)
                      : null,
                );
              },
            ),
    );
  }
}

// ─── Grade attendance card ────────────────────────────────────────────────────

class _GradeAttendanceCard extends StatelessWidget {
  final String grade;
  final List<Student> students;
  final AttendanceStatus? Function(int) statusFor;
  final Future<void> Function(int, AttendanceStatus) onRecord;

  const _GradeAttendanceCard({
    required this.grade,
    required this.students,
    required this.statusFor,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentCount =
        students.where((s) => statusFor(s.id!) == AttendanceStatus.present).length;
    final lateCount =
        students.where((s) => statusFor(s.id!) == AttendanceStatus.late).length;
    final absentCount = students.length - presentCount - lateCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Column(
          children: [
            // Grade header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withAlpha(26),
                    theme.colorScheme.primary.withAlpha(13),
                  ],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                border: Border(
                  right: BorderSide(
                      color: theme.colorScheme.primary, width: 4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(grade,
                        style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    '${students.length} طالب',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  _MiniStat(
                      count: presentCount, color: AppColors.emerald),
                  const SizedBox(width: 6),
                  _MiniStat(
                      count: lateCount, color: AppColors.yellow),
                  const SizedBox(width: 6),
                  _MiniStat(
                      count: absentCount, color: AppColors.red),
                ],
              ),
            ),

            // Student rows
            ...students.asMap().entries.map((entry) {
              final idx = entry.key;
              final student = entry.value;
              final status = statusFor(student.id!);
              return _AttendanceRow(
                index: idx + 1,
                student: student,
                status: status,
                onRecord: (s) => onRecord(student.id!, s),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final int count;
  final Color color;

  const _MiniStat({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
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

class _AttendanceRow extends StatelessWidget {
  final int index;
  final Student student;
  final AttendanceStatus? status;
  final ValueChanged<AttendanceStatus> onRecord;

  const _AttendanceRow({
    required this.index,
    required this.student,
    required this.status,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? rowBg;
    if (status == AttendanceStatus.present) {
      rowBg = AppColors.emerald.withAlpha(13);
    } else if (status == AttendanceStatus.late) {
      rowBg = AppColors.yellow.withAlpha(13);
    } else if (status == AttendanceStatus.absent) {
      rowBg = AppColors.red.withAlpha(13);
    }

    return Container(
      color: rowBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Roll number
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

          // Name
          Expanded(
            child: Text(
              student.name,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),

          // Status badge (defaults to absent if unrecorded)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (status == null
                      ? AppColors.red
                      : _statusColor(status!))
                  .withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status?.label ?? 'غائب (تلقائي)',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: status == null ? AppColors.red : _statusColor(status!),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AttendBtn(
                icon: Icons.check,
                color: AppColors.emerald,
                active: status == AttendanceStatus.present,
                tooltip: 'حاضر',
                onTap: () => onRecord(AttendanceStatus.present),
              ),
              const SizedBox(width: 6),
              _AttendBtn(
                icon: Icons.access_time,
                color: AppColors.yellow,
                active: status == AttendanceStatus.late,
                tooltip: 'متأخر',
                onTap: () => onRecord(AttendanceStatus.late),
              ),
              const SizedBox(width: 6),
              _AttendBtn(
                icon: Icons.close,
                color: AppColors.red,
                active: status == AttendanceStatus.absent,
                tooltip: 'غائب',
                onTap: () => onRecord(AttendanceStatus.absent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:
        return AppColors.emerald;
      case AttendanceStatus.late:
        return AppColors.yellow;
      case AttendanceStatus.absent:
        return AppColors.red;
    }
  }
}

class _AttendBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  const _AttendBtn({
    required this.icon,
    required this.color,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: active ? color : color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? color : color.withAlpha(77),
            ),
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : color,
            size: 18,
          ),
        ),
      ),
    );
  }
}
