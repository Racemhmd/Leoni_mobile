import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/design_system.dart';
import '../screens/sanctions_dashboard_screen.dart';
import '../screens/employee_sanctions_history_screen.dart';
import '../screens/hr_kpi_dashboard_screen.dart';

class AppDrawer extends StatelessWidget {
  final String userRole;

  const AppDrawer({Key? key, required this.userRole}) : super(key: key);

  bool get _isSupervisor => userRole == 'SUPERVISOR';
  bool get _isHrAdmin    => userRole == 'HR_ADMIN';
  bool get _hasAdminView => _isSupervisor || _isHrAdmin;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isSupervisor
                    ? [const Color(0xFF0A1628), const Color(0xFF0F1E38)]
                    : _isHrAdmin
                        ? [const Color(0xFF0F1628), const Color(0xFF1A2540)]
                        : [AppColors.employeePrimary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'LEONI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _roleLabel(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // ── Dashboard home ───────────────────────────────────────────────
          _DrawerItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            onTap: () => Navigator.pop(context),
          ),

          // ── Admin / Supervisor shared section ────────────────────────────
          if (_hasAdminView) ...[
            const _DrawerSectionLabel(label: 'ANALYTICS'),

            _DrawerItem(
              icon: Icons.analytics_outlined,
              label: 'KPI Dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HrKpiDashboardScreen(userRole: userRole),
                  ),
                );
              },
            ),

            _DrawerItem(
              icon: Icons.security_outlined,
              label: 'Sanctions',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SanctionsDashboardScreen(userRole: userRole),
                  ),
                );
              },
            ),

            _DrawerItem(
              icon: Icons.person_search_outlined,
              label: 'Sanctions par employé',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmployeeSanctionsHistoryScreen(userRole: userRole),
                  ),
                );
              },
            ),
          ],

          // ── Divider ──────────────────────────────────────────────────────
          if (_hasAdminView) const Divider(indent: 16, endIndent: 16),
        ],
      ),
    );
  }

  String _roleLabel() {
    switch (userRole) {
      case 'HR_ADMIN':    return 'HR Administration';
      case 'SUPERVISOR':  return 'Superviseur';
      default:            return userRole.replaceAll('_', ' ');
    }
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Drawer item ────────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  final Color?       color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return ListTile(
      leading: Icon(icon, color: c, size: 20),
      title: Text(
        label,
        style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 8,
    );
  }
}
