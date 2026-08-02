import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/study_group.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/motion/staggered_list_item.dart';
import '../widgets/motion/premium_interactive_widget.dart';
import '../widgets/motion/shimmer_loading.dart';

/// Dashboard — overview stats, study groups management, quick actions.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ─── Grade options ────────────────────────────────────────────────────────
  static const List<String> _grades = [
    'الصف الأول الإعدادي',
    'الصف الثاني الإعدادي',
    'الصف الثالث الإعدادي',
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 700;
    final padding = isTablet ? 28.0 : 16.0;

    if (app.loading) {
      return const Center(
        child: ShimmerLoading(width: 320, height: 160, borderRadius: 16),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: app.loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              _buildHeader(context, theme),
              const SizedBox(height: 28),

              // ── Stats grid ───────────────────────────────────────────────
              _buildStatsGrid(context, app, isTablet),
              const SizedBox(height: 32),

              // ── Two-column layout on tablet ───────────────────────────────
              if (isTablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildGroupsCard(context, app, theme),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildTeacherCard(context, theme),
                    ),
                  ],
                )
              else ...[
                _buildGroupsCard(context, app, theme),
                const SizedBox(height: 20),
                _buildTeacherCard(context, theme),
              ],

              const SizedBox(height: 32),

              // ── Today's attendance summary ────────────────────────────────
              if (app.todayAttendance.isNotEmpty)
                _buildAttendanceSummary(context, app, theme),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final now = DateTime.now();
    final weekdays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    final dateStr =
        '${weekdays[now.weekday - 1]}، ${now.day} ${months[now.month - 1]} ${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'لوحة التحكم',
          style: theme.textTheme.displayMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'مرحباً بك! إليك نظرة عامة على منصتك اليوم.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Stats grid ───────────────────────────────────────────────────────────

  Widget _buildStatsGrid(
      BuildContext context, AppProvider app, bool isTablet) {
    final crossAxisCount = isTablet ? 4 : 2;
    final stats = [
      (
        title: 'إجمالي الطلاب',
        value: '${app.totalStudents}',
        subtitle: 'طالب مسجل',
        icon: Icons.people_rounded,
        color: AppColors.primary,
      ),
      (
        title: 'حضور اليوم',
        value: '${app.presentToday}',
        subtitle: 'حاضرين حتى الآن',
        icon: Icons.check_circle_outline,
        color: AppColors.emerald,
      ),
      (
        title: 'نسبة الحضور',
        value: '${app.attendanceRate}%',
        subtitle: 'من الإجمالي',
        icon: Icons.trending_up,
        color: AppColors.orange,
      ),
      (
        title: 'الطلاب النشطين',
        value: '${app.activeStudents}',
        subtitle: 'متفاعلين',
        icon: Icons.school_outlined,
        color: AppColors.purple,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 125,
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) {
        final s = stats[i];
        return StaggeredListItem(
          index: i,
          child: PremiumInteractiveWidget(
            enableHoverGlow: true,
            child: StatCard(
              title: s.title,
              value: s.value,
              subtitle: s.subtitle,
              icon: s.icon,
              iconColor: s.color,
              borderColor: s.color,
            ),
          ),
        );
      },
    );
  }

  // ─── Study Groups card ────────────────────────────────────────────────────

  Widget _buildGroupsCard(
      BuildContext context, AppProvider app, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_work_rounded,
                    color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'المجموعات الدراسية',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showGroupDialog(context, app),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('مجموعة جديدة'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.primary.withAlpha(26),
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (app.groups.isEmpty)
              EmptyState(
                icon: Icons.group_work_outlined,
                message: 'لا توجد مجموعات مسجلة حالياً',
                actionLabel: 'إضافة مجموعة',
                onAction: () => _showGroupDialog(context, app),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 120,
                ),
                itemCount: app.groups.length,
                itemBuilder: (context, i) =>
                    _GroupTile(group: app.groups[i], app: app),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Teacher card ─────────────────────────────────────────────────────────

  Widget _buildTeacherCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(77),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'الشاعر في اللغة العربية',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'أ. محسن شاكر',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.people_outline,
              label: 'إجمالي الطلاب',
              value: '${context.watch<AppProvider>().totalStudents}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.group_work_outlined,
              label: 'المجموعات',
              value: '${context.watch<AppProvider>().groups.length}',
            ),
          ],
        ),
      ),
    );
  }

  // ─── Attendance summary ───────────────────────────────────────────────────

  Widget _buildAttendanceSummary(
      BuildContext context, AppProvider app, ThemeData theme) {
    final present = app.presentToday;
    final late = app.lateToday;
    final absent = app.totalStudents - present - late;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today_outlined,
                    color: AppColors.emerald, size: 22),
                const SizedBox(width: 10),
                Text('ملخص حضور اليوم', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _AttendancePill(
                    label: 'حاضر', count: present, color: AppColors.emerald),
                const SizedBox(width: 12),
                _AttendancePill(
                    label: 'متأخر', count: late, color: AppColors.yellow),
                const SizedBox(width: 12),
                _AttendancePill(
                    label: 'غائب', count: absent, color: AppColors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Group dialog ─────────────────────────────────────────────────────────

  void _showGroupDialog(BuildContext context, AppProvider app,
      {StudyGroup? existing}) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final scheduleCtrl =
        TextEditingController(text: existing?.schedule ?? '');
    String selectedGrade = existing?.grade ?? _grades.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
              existing == null ? 'إضافة مجموعة دراسية' : 'تعديل المجموعة'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم المجموعة',
                    hintText: 'مثال: سبت وإثنين 4 عصراً',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedGrade,
                  decoration:
                      const InputDecoration(labelText: 'الصف الدراسي'),
                  items: _grades
                      .map((g) =>
                          DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedGrade = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: scheduleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'المواعيد (اختياري)',
                    hintText: 'مثال: السبت والإثنين 4 م',
                  ),
                ),
              ],
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
                final group = StudyGroup(
                  id: existing?.id,
                  name: nameCtrl.text.trim(),
                  grade: selectedGrade,
                  schedule: scheduleCtrl.text.trim().isEmpty
                      ? null
                      : scheduleCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (existing == null) {
                  await app.addGroup(group);
                } else {
                  await app.updateGroup(group);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _GroupTile extends StatelessWidget {
  final StudyGroup group;
  final AppProvider app;

  const _GroupTile({required this.group, required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'حذف المجموعة',
                    message: 'هل تريد حذف "${group.name}"؟',
                    confirmLabel: 'حذف',
                  );
                  if (confirmed && context.mounted) {
                    await app.deleteGroup(group.id!);
                  }
                },
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: theme.colorScheme.error.withAlpha(153),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              group.grade,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (group.schedule != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule_outlined,
                    size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    group.schedule!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
        ),
      ),
    );
  }
}
 
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: theme.colorScheme.onSurface.withAlpha(102)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _AttendancePill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AttendancePill(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 28,
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
          ],
        ),
      ),
    );
  }
}
