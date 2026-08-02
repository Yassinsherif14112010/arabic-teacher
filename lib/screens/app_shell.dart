import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'students_screen.dart';
import 'attendance_screen.dart';
import 'payments_screen.dart';
import 'exams_screen.dart';
import 'auth/security_settings_dialog.dart';

/// Navigation destination descriptor.
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });
}

/// Root shell that provides the sidebar (tablet) or bottom nav (phone)
/// and hosts all main screens.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _drawerOpen = false;

  static const List<_NavItem> _items = [
    _NavItem(
      label: 'لوحة التحكم',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      screen: DashboardScreen(),
    ),
    _NavItem(
      label: 'إدارة الطلاب',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      screen: StudentsScreen(),
    ),
    _NavItem(
      label: 'تسجيل الحضور',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      screen: AttendanceScreen(),
    ),
    _NavItem(
      label: 'المصروفات',
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments,
      screen: PaymentsScreen(),
    ),
    _NavItem(
      label: 'الامتحانات',
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
      screen: ExamsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    if (isTablet) {
      return _TabletLayout(
        items: _items,
        selectedIndex: _selectedIndex,
        onSelect: (i) => setState(() => _selectedIndex = i),
      );
    }

    return _PhoneLayout(
      items: _items,
      selectedIndex: _selectedIndex,
      onSelect: (i) => setState(() => _selectedIndex = i),
      drawerOpen: _drawerOpen,
      onDrawerToggle: () => setState(() => _drawerOpen = !_drawerOpen),
    );
  }
}

// ─── Tablet Layout ────────────────────────────────────────────────────────────

class _TabletLayout extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _TabletLayout({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sidebarBg = isDark ? AppColors.darkSidebar : AppColors.lightSidebar;

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          SizedBox(
            width: 260,
            child: _Sidebar(
              items: items,
              selectedIndex: selectedIndex,
              onSelect: onSelect,
              backgroundColor: sidebarBg,
            ),
          ),
          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: IndexedStack(
                key: ValueKey<int>(selectedIndex),
                index: selectedIndex,
                children: items.map((i) => i.screen).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Phone Layout ─────────────────────────────────────────────────────────────

class _PhoneLayout extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool drawerOpen;
  final VoidCallback onDrawerToggle;

  const _PhoneLayout({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.drawerOpen,
    required this.onDrawerToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? AppColors.darkSidebar : AppColors.lightSidebar;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: onDrawerToggle,
        ),
        title: Text(items[selectedIndex].label),
      ),
      drawer: Drawer(
        backgroundColor: sidebarBg,
        child: _Sidebar(
          items: items,
          selectedIndex: selectedIndex,
          onSelect: (i) {
            onSelect(i);
            Navigator.pop(context);
          },
          backgroundColor: sidebarBg,
        ),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: items.map((i) => i.screen).toList(),
      ),
    );
  }
}

// ─── Sidebar Widget ───────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Color backgroundColor;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Logo / Brand ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(50),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الشاعر',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'في اللغة العربية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Teacher info ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(13)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(26)
                      : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withAlpha(51),
                    child: Icon(
                      Icons.person,
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primaryDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أ. محسن شاكر',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'مدرس اللغة العربية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            color: isDark
                                ? AppColors.primaryLight
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Security / Audit Log button
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const SecuritySettingsDialog(),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha(13)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.security_outlined,
                        color: AppColors.emerald,
                        size: 18,
                      ),
                    ),
                  ),
                  // Theme toggle
                  GestureDetector(
                    onTap: themeProvider.toggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha(13)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        themeProvider.isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF334155),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(
              color:
                  isDark ? Colors.white.withAlpha(26) : AppColors.lightBorder,
              height: 1,
            ),
            const SizedBox(height: 8),

            // ── Navigation items ──────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isActive = index == selectedIndex;
                  return _NavTile(
                    item: item,
                    isActive: isActive,
                    onTap: () => onSelect(index),
                  );
                },
              ),
            ),

            // ── Sync & Footer ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<AppProvider>(
                builder: (context, app, _) {
                  final pending = app.pendingSyncCount;
                  final status = app.syncStatus;
                  IconData icon = Icons.cloud_done;
                  Color color =
                      isDark ? Colors.greenAccent : const Color(0xFF059669);
                  String label = 'مُزامن مع السحابة';

                  if (status == SyncStatus.offline ||
                      !SyncService.isConfigured) {
                    icon = Icons.cloud_off;
                    color =
                        isDark ? Colors.orangeAccent : const Color(0xFFEA580C);
                    label = pending > 0
                        ? 'أوفلاين ($pending معلقة)'
                        : 'أوفلاين (SQLite)';
                  } else if (status == SyncStatus.syncing) {
                    icon = Icons.sync;
                    color = isDark ? Colors.blueAccent : AppColors.primaryDark;
                    label = 'جاري المزامن...';
                  } else if (status == SyncStatus.error) {
                    icon = Icons.cloud_queue;
                    color = isDark ? Colors.redAccent : AppColors.red;
                    label = 'خطأ في المزامن';
                  }

                  return InkWell(
                    onTap: app.syncNow,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withAlpha(51)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isActive
                  ? AppColors.primary.withAlpha(isDark ? 51 : 30)
                  : Colors.transparent,
              border: isActive
                  ? Border.all(
                      color: AppColors.primary.withAlpha(isDark ? 77 : 60))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive
                      ? (isDark
                          ? AppColors.primaryLight
                          : AppColors.primaryDark)
                      : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? (isDark ? Colors.white : AppColors.primaryDark)
                          : (isDark ? Colors.white60 : const Color(0xFF475569)),
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
