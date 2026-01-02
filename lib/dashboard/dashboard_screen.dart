import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../points/history_screen.dart';
import '../leaves/leave_request_screen.dart';
import '../points/xmall_screen.dart';
import '../auth/login_screen.dart';
import 'admin_screen.dart';
import 'supervisor_screen.dart'; // Import Supervisor Screen

// New Widgets
import '../widgets/points_summary_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/earn_spend_guide.dart'; // Import Guide

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  int _points = 0;
  String _role = '';
  String _fullName = '';
  String _matricule = '';
  List<dynamic> _recentActivity = [];
  bool _isLoading = true;

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
            // Unify UI: Show EMPLOYEE even if backend returns OPERATOR
            _role = (roleName == 'OPERATOR') ? 'EMPLOYEE' : (roleName ?? '');
            _fullName = userData['full_name'] ?? 'Employee';
            _matricule = userData['matricule'] ?? '';
          });
      }
      
      // Only fetch points if allowed (EMPLOYEE / OPERATOR)
      if (!_isRestricted()) {
        final pointsData = await _apiService.get('/points/balance');
        final historyData = await _apiService.get('/points/history');
        
        setState(() {
          _points = pointsData['points'];
          if (historyData is List) {
            _recentActivity = historyData;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isRestricted() {
    final r = _role.trim().toUpperCase();
    return r == 'HR_ADMIN' || r == 'SUPERVISOR';
  }

  void _navigateTo(Widget screen) {
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

    // Default: Employee / Operator View
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF003366)),
        centerTitle: true,
        title: Text(
          'LEONI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: const Color(0xFF003366), letterSpacing: 1.0),
        ),
        actions: [
          const EarnSpendGuide(), 
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic Header
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text('Welcome, your progress starts here.', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14)),
                         const SizedBox(height: 8),
                         Text(_fullName.toUpperCase(), style: GoogleFonts.outfit(color: const Color(0xFF003366), fontSize: 24, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 8),
                         Row(
                           children: [
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                               child: Text('MAT: $_matricule', style: GoogleFonts.robotoMono(color: Colors.grey.shade800, fontSize: 12, fontWeight: FontWeight.w500)),
                             ),
                             const SizedBox(width: 8),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(color: const Color(0xFF003366).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                               child: Text(_role.toUpperCase(), style: GoogleFonts.roboto(color: const Color(0xFF003366), fontSize: 11, fontWeight: FontWeight.bold)),
                             ),
                           ],
                         ),
                      ],
                    ),
                  ),

                  if (!_isRestricted()) ...[
                    PointsSummaryCard(
                      points: _points,
                      role: _role,
                      onTap: () => _navigateTo(const HistoryScreen()),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  QuickActionsGrid(
                    actions: [
                      // Only show if not restricted
                      if (!_isRestricted()) ...[
                        QuickActionItem(
                          icon: Icons.history,
                          label: 'My History',
                          onTap: () => _navigateTo(const HistoryScreen()),
                        ),
                        QuickActionItem(
                          icon: Icons.shopping_bag,
                          label: 'XMALL Store',
                          onTap: () => _navigateTo(const XmallScreen()),
                        ),
                      ],
                      // Common actions
                      QuickActionItem(
                        icon: Icons.add_circle_outline,
                        label: 'New Request',
                        onTap: () => _navigateTo(const LeaveRequestScreen()),
                        color: const Color(0xFF003366),
                      ),
                      QuickActionItem(
                        icon: Icons.pending_actions,
                        label: 'Leave Status',
                        onTap: () => _navigateTo(const LeaveRequestScreen()), // Consolidated screen for now
                        color: const Color(0xFFE65100), // Different color for distinction
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  if (!_isRestricted()) ...[
                      Text(
                        'RECENT ACTIVITY',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RecentActivityList(
                        activities: _recentActivity,
                        onViewAll: () => _navigateTo(const HistoryScreen()),
                      ),
                      const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
    );
  }
}
