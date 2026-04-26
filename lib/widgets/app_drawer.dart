import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/design_system.dart';
import '../screens/sanctions_dashboard_screen.dart';
import '../screens/employee_sanctions_history_screen.dart';
import '../screens/hr_kpi_dashboard_screen.dart';

class AppDrawer extends StatelessWidget {
  final String userRole;

  const AppDrawer({Key? key, required this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: userRole == 'EMPLOYEE' ? AppColors.employeePrimary : AppColors.adminPrimary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('LEONI', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                Text(userRole.replaceAll('_', ' '), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context); // Just close the drawer to stay on Dashboard
            },
          ),
          if (userRole == 'HR_ADMIN' || userRole == 'SUPERVISOR') ...[
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('HR KPI Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HrKpiDashboardScreen(userRole: userRole)),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
