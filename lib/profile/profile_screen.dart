import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/points_service.dart';
import '../auth/login_screen.dart';
import '../theme/design_system.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _pointsService = PointsService();
  final _storage = const FlutterSecureStorage();
  
  bool _isLoading = true;
  String _fullName = '';
  String _matricule = '';
  String _role = '';
  
  // Points Stats
  double _totalGained = 0;
  double _totalLost = 0;
  double _balance = 0;
  
  // Settings
  bool _pushEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _apiService.get('/auth/me');
      if (mounted) {
         setState(() {
            _fullName = userData['fullName'] ?? userData['full_name'] ?? 'User';
            _matricule = userData['matricule'] ?? '';
            final roleName = userData['role'] is Map ? userData['role']['name'] : userData['role'];
            _role = roleName ?? '';
         });
      }

      if (_role == 'EMPLOYEE' || _role == 'OPERATOR') {
          final summary = await _pointsService.getSummary();
          setState(() {
              _balance = (summary['balance'] is int) ? (summary['balance'] as int).toDouble() : summary['balance'];
              _totalGained = (summary['totalGainedYearly'] is int) ? (summary['totalGainedYearly'] as int).toDouble() : summary['totalGainedYearly'];
              _totalLost = (summary['totalLostYearly'] is int) ? (summary['totalLostYearly'] as int).toDouble() : summary['totalLostYearly'];
          });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (mounted) {
       Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Profile', style: AppTypography.headerMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  // User Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?',
                            style: AppTypography.headerLarge.copyWith(color: AppColors.primary, fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_fullName, style: AppTypography.headerSmall),
                            Text('Matricule: $_matricule', style: AppTypography.bodySmall.copyWith(color: AppColors.textLight)),
                            Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4)
                                ),
                                child: Text(_role, style: AppTypography.button.copyWith(color: AppColors.secondary, fontSize: 10))
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (_role == 'EMPLOYEE' || _role == 'OPERATOR') ...[
                      Align(alignment: Alignment.centerLeft, child: Text('POINTS STATISTICS (YEARLY)', style: AppTypography.label)),
                      const SizedBox(height: AppSpacing.m),
                      Row(
                          children: [
                              Expanded(child: _buildStatCard('Gained', '+${_totalGained.toStringAsFixed(1)}', AppColors.success)),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(child: _buildStatCard('Lost', '-${_totalLost.toStringAsFixed(1)}', AppColors.error)),
                          ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                  ],

                  Align(alignment: Alignment.centerLeft, child: Text('SETTINGS', style: AppTypography.label)),
                  const SizedBox(height: AppSpacing.m),
                  Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
                      ),
                      child: Column(
                          children: [
                              SwitchListTile(
                                  title: Text('Push Notifications', style: AppTypography.bodyMedium),
                                  value: _pushEnabled,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) => setState(() => _pushEnabled = val),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                  title: Text('Change Password', style: AppTypography.bodyMedium),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                      // Navigate to change password
                                  },
                              ),
                          ],
                      ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: _logout,
                          child: const Text('Log Out'),
                      ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
      return Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
          ),
          child: Column(
              children: [
                  Text(label.toUpperCase(), style: AppTypography.label.copyWith(fontSize: 10)),
                  const SizedBox(height: 8),
                  Text(value, style: AppTypography.headerMedium.copyWith(color: color)),
              ],
          ),
      );
  }
}
