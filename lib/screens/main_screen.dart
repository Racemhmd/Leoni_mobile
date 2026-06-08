import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/admin_screen.dart';
import '../dashboard/supervisor_screen.dart';
import '../points/history_screen.dart';
import '../points/xmall_screen.dart';
import '../profile/profile_screen.dart';
import '../widgets/notification_bell.dart';
import '../theme/design_system.dart';

/// Post-login application shell.
/// Routes admin/supervisor to their dedicated screens, and wraps the employee
/// experience in a BottomNavigationBar with 4 tabs.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _role = '';
  bool _isLoading = true;

  static const _tabLabels = ['Accueil', 'Transactions', 'Récompenses', 'Profil'];
  static const _tabIcons = [
    Icons.home_outlined,
    Icons.swap_vert_outlined,
    Icons.card_giftcard_outlined,
    Icons.person_outline_rounded,
  ];
  static const _tabActiveIcons = [
    Icons.home_rounded,
    Icons.swap_vert_rounded,
    Icons.card_giftcard_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _detectRole();
  }

  Future<void> _detectRole() async {
    try {
      final data = await ApiService().get('/auth/me');
      final roleName = data['role'] is Map
          ? (data['role']['name'] as String? ?? '')
          : (data['role'] as String? ?? '');
      if (!mounted) return;
      setState(() {
        _role = roleName.trim().toUpperCase();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Non-employee roles → their own full-screen UIs
    if (_role == 'HR_ADMIN') return const AdminScreen();
    if (_role == 'SUPERVISOR') return const SupervisorScreen();

    // Employee / Operator → BottomNav experience
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardScreen(),
          HistoryScreen(),
          XmallScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = i);
        },
        labels: _tabLabels,
        icons: _tabIcons,
        activeIcons: _tabActiveIcons,
      ),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> activeIcons;

  const _AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.labels,
    required this.icons,
    required this.activeIcons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.floatingNav,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.s, horizontal: AppSpacing.s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(labels.length, (i) {
              final active = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: AppDurations.normal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: active ? AppGradients.brand : null,
                          color: active ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          boxShadow: active ? AppShadows.primaryGlow : null,
                        ),
                        child: Icon(
                          active ? activeIcons[i] : icons[i],
                          color: active ? Colors.white : AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: AppDurations.normal,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.normal,
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        child: Text(labels[i]),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
