import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../auth/login_screen.dart';
import '../theme/design_system.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class SupervisorScreen extends StatefulWidget {
  const SupervisorScreen({super.key});

  @override
  State<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<SupervisorScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  String _supervisorName = '';
  int _presentCount = 0;
  int _absentCount = 0;
  List<dynamic> _pendingApprovals = []; // Mock for now

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _apiService.get('/auth/me');
      if (mounted) {
        setState(() {
           _supervisorName = user['fullName'] ?? 'Supervisor';
        });
      }
      
      // Mock Data for demo until endpoints match
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
           _presentCount = 42;
           _absentCount = 3;
           _pendingApprovals = [
             {'id': 101, 'name': 'Ahmed Ben Ali', 'type': 'Points', 'val': 50, 'reason': 'Extra Shift'},
             {'id': 102, 'name': 'Sarra Mejri', 'type': 'Leave', 'val': '1 Day', 'reason': 'Sick Leave'},
           ];
           _isLoading = false;
        });
      }
    } catch (e) {
       debugPrint('Error: $e');
       if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reuse Admin Theme for Supervisor (Authoritative)
    return Theme(
      data: AppTheme.adminTheme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: const AppDrawer(userRole: 'SUPERVISOR'),
        appBar: AppBar(
          title: Text('TEAM SUPERVISION', style: AppTypography.headerSmall.copyWith(color: Colors.white, letterSpacing: 1.5)),
          actions: [
            IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                  await _apiService.logout();
                  if (context.mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
                   // WELCOME HEADER
                   Text('Hello, $_supervisorName', style: AppTypography.headerMedium.copyWith(color: AppColors.adminPrimary)),
                   Text('Here is your team overview today.', style: AppTypography.bodyMedium),
                   const SizedBox(height: AppSpacing.l),

                   // STATS ROW
                   Row(
                     children: [
                       Expanded(child: _buildStatCard('Present Team', '$_presentCount', Icons.check_circle_outline, AppColors.success)),
                       const SizedBox(width: AppSpacing.m),
                       Expanded(child: _buildStatCard('Absent', '$_absentCount', Icons.warning_amber_rounded, AppColors.error)),
                     ],
                   ),
                   const SizedBox(height: AppSpacing.xl),

                   // PENDING APPROVALS
                   Text('PENDING APPROVALS', style: AppTypography.label),
                   const SizedBox(height: AppSpacing.m),
                   _pendingApprovals.isEmpty 
                    ? const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No pending items.')))
                    : Column(
                        children: _pendingApprovals.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Text(item['name'][0], style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            title: Text(item['name'], style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item['type']} • ${item['reason']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.check, color: AppColors.success), onPressed: (){
                                  setState(() => _pendingApprovals.remove(item));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved')));
                                }),
                                IconButton(icon: const Icon(Icons.close, color: AppColors.error), onPressed: (){
                                  setState(() => _pendingApprovals.remove(item));
                                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected')));
                                }),
                              ],
                            ),
                          ),
                        )).toList(),
                    ),
                ],
              ),
          ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Icon(icon, color: color, size: 28),
           const SizedBox(height: 12),
           Text(value, style: AppTypography.headerLarge.copyWith(color: AppColors.textDark)),
           Text(title, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
