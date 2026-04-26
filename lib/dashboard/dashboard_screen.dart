import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/points_service.dart';
import '../services/api_service.dart'; 
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'admin_screen.dart';
import 'supervisor_screen.dart';
import '../points/history_screen.dart';
import '../points/xmall_screen.dart';
import '../leaves/leave_request_screen.dart';
import '../theme/app_theme.dart';
import '../theme/design_system.dart';
import '../widgets/quick_actions_grid.dart'; 
import '../widgets/recent_activity_list.dart';
import '../widgets/earn_spend_guide.dart'; 
import '../widgets/qr_card.dart';
import '../widgets/points_summary_card.dart'; // Make sure this is imported if used
import '../widgets/notification_bell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  int _points = 0;
  double _dtValue = 0.0;
  String _role = '';
  String _fullName = '';
  String _matricule = '';
  List<dynamic> _recentActivity = [];
  bool _isLoading = true;

  final _pointsService = PointsService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Get fresh user data from backend
      final userData = await _apiService.get('/auth/me');
      if (mounted) {
          final roleName = userData['role'] is Map ? userData['role']['name'] : userData['role'];
          setState(() {
            _role = (roleName == 'OPERATOR') ? 'EMPLOYEE' : (roleName ?? '');
            _fullName = userData['fullName'] ?? 'Employee';
            if (_fullName == 'Employee') _fullName = userData['full_name'] ?? 'Employee'; // Fallback
            _matricule = userData['matricule'] ?? '';
          });
      }
      
      // Only fetch points if allowed (EMPLOYEE / OPERATOR)
      if (!_isRestricted()) {
        try {
          final summary = await _pointsService.getSummary();
          final history = await _pointsService.getHistory('month'); // Default to month
          
          setState(() {
            _points = summary['balance'] is int ? summary['balance'] : (summary['balance'] as double).toInt();
            _dtValue = (summary['dtValue'] is int) ? (summary['dtValue'] as int).toDouble() : summary['dtValue'];
            if (history is List) {
              _recentActivity = history;
            }
          });
        } catch (e) {
           print('Error fetching points: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isRestricted() {
    final r = _role.trim().toUpperCase();
    return r != 'EMPLOYEE';
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    // strict redirects
    final r = _role.trim().toUpperCase();
    if (r == 'HR_ADMIN') {
        return const AdminScreen();
    }
    if (r == 'SUPERVISOR') {
        return const SupervisorScreen();
    }

    // Default: Employee / Operator View - Gamified Theme
    return Theme(
      data: AppTheme.employeeTheme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppColors.primary),
          centerTitle: true,
          title: Text(
            'LEONI',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.primary, letterSpacing: 2.0),
          ),
          actions: [
            if (!_isRestricted()) const EarnSpendGuide(),
            const NotificationBell(),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => _navigateTo(const ProfileScreen()),
            ), 
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                 await _apiService.logout();
                 if (context.mounted) {
                   Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                 }
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppSpacing.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text('Welcome back,', style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight)),
                           Text(_fullName.toUpperCase(), style: AppTypography.headerMedium.copyWith(color: AppColors.employeePrimary)),
                        ],
                      ),
                    ),

                    if (!_isRestricted()) ...[
                      PointsSummaryCard(
                        points: _points,
                        dtValue: _dtValue,
                        role: _role,
                        onTap: () => _navigateTo(const HistoryScreen()),
                      ),
                      
                      QrCard(matricule: _matricule), 
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    Text(
                      'QUICK ACTIONS',
                      style: AppTypography.label,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    QuickActionsGrid(
                      actions: [
                        if (!_isRestricted()) ...[
                          QuickActionItem(
                            icon: Icons.history,
                            label: 'History',
                            onTap: () => _navigateTo(const HistoryScreen()),
                          ),
                          QuickActionItem(
                            icon: Icons.shopping_bag,
                            label: 'XMALL',
                            onTap: () => _navigateTo(const XmallScreen()),
                          ),
                        ],
                        QuickActionItem(
                          icon: Icons.add_circle_outline,
                          label: 'Request',
                          onTap: () => _navigateTo(const LeaveRequestScreen()),
                          color: AppColors.employeePrimary,
                        ),
                        QuickActionItem(
                          icon: Icons.pending_actions,
                          label: 'Status',
                          onTap: () => _navigateTo(const LeaveRequestScreen()), 
                          color: AppColors.secondary, 
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    if (!_isRestricted()) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('RECENT ACTIVITY', style: AppTypography.label),
                            TextButton(onPressed: () => _navigateTo(const HistoryScreen()), child: const Text('View All')) 
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),
                        RecentActivityList(
                          activities: _recentActivity,
                          onViewAll: () => _navigateTo(const HistoryScreen()),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
