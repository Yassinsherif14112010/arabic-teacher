import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/grade.dart';
import '../models/student.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/confirm_dialog.dart';
import 'students_screen.dart' show kGrades;
import '../widgets/motion/shimmer_loading.dart';

/// Exams & Grades screen — per-student grade tracking with stats.
class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  bool _showForm = false;
  String _filterGrade = '';
  ExamType? _filterType;
  Student? _selectedStudent;
  List<Grade> _studentGrades = [];
  bool _loadingGrades = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);

    final contentWidth = ContentWidthProvider.of(context);
    final isTablet = contentWidth >= 480;
    final padding = isTablet ? 20.0 : 16.0;

    // Filter students by grade
    final filteredStudents = _filterGrade.isEmpty
        ? app.students
        : app.students.where((s) => s.grade == _filterGrade).toList();

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
                const Icon(Icons.school_rounded,
                    color: AppColors.purple, size: 26),
                const SizedBox(width: 12),
                Text('الامتحانات والدرجات',
                    style: theme.textTheme.headlineMedium),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _showForm = !_showForm),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('تسجيل درجة'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Add grade form ───────────────────────────────────────────
            if (_showForm) ...[
              _AddGradeForm(
                app: app,
                onDone: () => setState(() => _showForm = false),
                onAdded: () async {
                  if (_selectedStudent != null) {
                    await _loadGrades(_selectedStudent!);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // ── Filters ──────────────────────────────────────────────────
            if (isTablet)
              Row(
                children: [
                  Expanded(child: _buildGradeFilter(theme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStudentSelector(filteredStudents, theme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTypeFilter(theme)),
                ],
              )
            else ...[
              _buildGradeFilter(theme),
              const SizedBox(height: 10),
              _buildStudentSelector(filteredStudents, theme),
              const SizedBox(height: 10),
              _buildTypeFilter(theme),
            ],
            const SizedBox(height: 24),

            // ── Student grades ───────────────────────────────────────────
            if (_selectedStudent == null)
              const EmptyState(
                icon: Icons.school_outlined,
                message: 'اختر طالباً لعرض درجاته',
              )
            else if (_loadingGrades)
              const Center(child: ShimmerLoading(width: 300, height: 120, borderRadius: 12))
            else ...[
              _buildStudentStats(theme),
              const SizedBox(height: 16),
              _buildGradesTable(theme),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadGrades(Student student) async {
    setState(() => _loadingGrades = true);
    final app = context.read<AppProvider>();
    final grades = await app.getGradesForStudent(student.id!);
    if (mounted) {
      setState(() {
        _studentGrades = grades;
        _loadingGrades = false;
      });
    }
  }

  Widget _buildGradeFilter(ThemeData theme) {
    return DropdownButtonFormField<String?>(
      isExpanded: true,
      initialValue: _filterGrade.isEmpty ? null : _filterGrade,
      decoration: const InputDecoration(labelText: 'تصفية بالصف'),
      items: [
        const DropdownMenuItem(value: null, child: Text('كل الصفوف', overflow: TextOverflow.ellipsis)),
        ...kGrades.map((g) => DropdownMenuItem(value: g, child: Text(g, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (v) => setState(() {
        _filterGrade = v ?? '';
        _selectedStudent = null;
        _studentGrades = [];
      }),
    );
  }

  Widget _buildStudentSelector(
      List<Student> students, ThemeData theme) {
    return DropdownButtonFormField<Student?>(
      isExpanded: true,
      initialValue: _selectedStudent,
      decoration:
          const InputDecoration(labelText: 'عرض درجات طالب'),
      items: [
        const DropdownMenuItem(
            value: null, child: Text('اختر طالب لعرض درجاته', overflow: TextOverflow.ellipsis)),
        ...students.map((s) => DropdownMenuItem(
            value: s,
            child: Text(
                '${s.name}${s.grade != null ? ' (${s.grade})' : ''}', overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (v) async {
        setState(() {
          _selectedStudent = v;
          _studentGrades = [];
        });
        if (v != null) await _loadGrades(v);
      },
    );
  }

  Widget _buildTypeFilter(ThemeData theme) {
    return DropdownButtonFormField<ExamType?>(
      isExpanded: true,
      initialValue: _filterType,
      decoration: const InputDecoration(labelText: 'نوع الامتحان'),
      items: [
        const DropdownMenuItem(value: null, child: Text('كل الأنواع', overflow: TextOverflow.ellipsis)),
        ...ExamType.values.map((t) =>
            DropdownMenuItem(value: t, child: Text(t.label, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (v) => setState(() => _filterType = v),
    );
  }

  Widget _buildStudentStats(ThemeData theme) {
    final filtered = _filterType == null
        ? _studentGrades
        : _studentGrades.where((g) => g.examType == _filterType).toList();

    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart_outlined,
        message: 'لا توجد درجات مسجلة لهذا الطالب',
      );
    }

    final avg = filtered.fold<double>(0, (s, g) => s + g.score) /
        filtered.length;
    final top = filtered.map((g) => g.score).reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'عدد الامتحانات',
            value: '${filtered.length}',
            icon: Icons.quiz_outlined,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            label: 'متوسط الدرجات',
            value: avg.toStringAsFixed(1),
            icon: Icons.trending_up,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            label: 'أعلى درجة',
            value: top.toStringAsFixed(1),
            icon: Icons.emoji_events_outlined,
            color: AppColors.emerald,
          ),
        ),
      ],
    );
  }

  Widget _buildGradesTable(ThemeData theme) {
    final filtered = _filterType == null
        ? _studentGrades
        : _studentGrades.where((g) => g.examType == _filterType).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              'درجات: ${_selectedStudent!.name}',
              style: theme.textTheme.titleMedium,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  theme.colorScheme.surface),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('المادة / الموضوع')),
                DataColumn(label: Text('النوع')),
                DataColumn(label: Text('الدرجة')),
                DataColumn(label: Text('النسبة')),
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('ملاحظات')),
                DataColumn(label: Text('')),
              ],
              rows: filtered.asMap().entries.map((entry) {
                final idx = entry.key;
                final g = entry.value;
                final pct = g.percentage;
                final passing = g.isPassing;

                return DataRow(cells: [
                  DataCell(Text('${idx + 1}')),
                  DataCell(Text(g.subject ?? '—')),
                  DataCell(_ExamTypeBadge(type: g.examType)),
                  DataCell(Text(
                    '${g.score.toStringAsFixed(1)} / ${g.maxScore.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: passing ? AppColors.emerald : AppColors.red,
                    ),
                  )),
                  DataCell(Text(g.examDate)),
                  DataCell(Text(g.notes ?? '—')),
                  DataCell(IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: theme.colorScheme.error, size: 18),
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'حذف الدرجة',
                        message: 'هل تريد حذف هذه الدرجة؟',
                        confirmLabel: 'حذف',
                      );
                      if (confirmed && context.mounted) {
                        // ignore: use_build_context_synchronously
                        await context.read<AppProvider>().deleteGrade(g.id!);
                        if (_selectedStudent != null) {
                          await _loadGrades(_selectedStudent!);
                        }
                      }
                    },
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add grade form ───────────────────────────────────────────────────────────

class _AddGradeForm extends StatefulWidget {
  final AppProvider app;
  final VoidCallback onDone;
  final VoidCallback onAdded;

  const _AddGradeForm({
    required this.app,
    required this.onDone,
    required this.onAdded,
  });

  @override
  State<_AddGradeForm> createState() => _AddGradeFormState();
}

class _AddGradeFormState extends State<_AddGradeForm> {
  int? _studentId;
  ExamType _examType = ExamType.daily;
  final _scoreCtrl = TextEditingController();
  final _maxScoreCtrl = TextEditingController(text: '100');
  final _subjectCtrl = TextEditingController(text: 'اللغة العربية');
  final _notesCtrl = TextEditingController();
  late final TextEditingController _dateCtrl;

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _dateCtrl = TextEditingController(text: _todayStr());
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _maxScoreCtrl.dispose();
    _subjectCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = widget.app;

    final score = double.tryParse(_scoreCtrl.text) ?? 0;
    final maxScore = double.tryParse(_maxScoreCtrl.text) ?? 100;
    final pct = maxScore > 0 ? (score / maxScore) * 100 : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('تسجيل درجة امتحان',
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
                          value: null, child: Text('اختر الطالب')),
                      ...app.students.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            '${s.name}${s.grade != null ? ' (${s.grade})' : ''}',
                            overflow: TextOverflow.ellipsis,
                          ))),
                    ],
                    onChanged: (v) => setState(() => _studentId = v),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<ExamType>(
                    isExpanded: true,
                    initialValue: _examType,
                    decoration:
                        const InputDecoration(labelText: 'نوع الامتحان'),
                    items: ExamType.values
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.label, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _examType = v!),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _subjectCtrl,
                    decoration: const InputDecoration(
                        labelText: 'المادة / الموضوع'),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _scoreCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'الدرجة *'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _maxScoreCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'الدرجة الكاملة'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    decoration: const InputDecoration(
                        labelText: 'تاريخ الامتحان (yyyy-MM-dd)'),
                    controller: _dateCtrl,
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

            // Score preview
            if (_scoreCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('النسبة المئوية: ',
                        style: theme.textTheme.bodySmall),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: pct >= 50 ? AppColors.emerald : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_studentId == null) return;
                    final score =
                        double.tryParse(_scoreCtrl.text.trim()) ?? 0;
                    final maxScore =
                        double.tryParse(_maxScoreCtrl.text.trim()) ?? 100;
                    await widget.app.addGrade(Grade(
                      studentId: _studentId!,
                      examType: _examType,
                      score: score,
                      maxScore: maxScore,
                      examDate: _dateCtrl.text.trim(),
                      subject: _subjectCtrl.text.trim().isEmpty
                          ? null
                          : _subjectCtrl.text.trim(),
                      notes: _notesCtrl.text.trim().isEmpty
                          ? null
                          : _notesCtrl.text.trim(),
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('✅ تم تسجيل الدرجة بنجاح!')),
                      );
                      widget.onAdded();
                      widget.onDone();
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('حفظ الدرجة'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple),
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

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _ExamTypeBadge extends StatelessWidget {
  final ExamType type;

  const _ExamTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = type == ExamType.daily
        ? AppColors.primary
        : type == ExamType.monthly
            ? AppColors.purple
            : AppColors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.label,
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

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
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
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
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
