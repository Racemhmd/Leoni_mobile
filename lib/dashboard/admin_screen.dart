import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; 
import '../services/api_service.dart';
import '../auth/login_screen.dart';
import 'audit_log_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../theme/design_system.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _apiService = ApiService();
  
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _adminName = '';
  int _pendingLeavesCount = 0;
  int _alertsCount = 0; 
  int _totalEmployees = 0;
  // Chart Data Mock
  int _employeeCount = 0;
  int _supervisorCount = 0;
  int _adminCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadDashboardData();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _apiService.get('/auth/me');
      if (mounted) {
        setState(() {
          final fullName = user['fullName'];
          _adminName = fullName?.toString() ?? 'HR Admin';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }
  
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Users
      List<dynamic> usersData = [];
      try {
        final res = await _apiService.get('/users');
        if (res is List) {
           usersData = res;
           // Sort by role: HR_ADMIN > SUPERVISOR > EMPLOYEE
           usersData.sort((a, b) {
              final roleA = _getRoleName(a).toUpperCase();
              final roleB = _getRoleName(b).toUpperCase();
              
              int getPriority(String role) {
                if (role == 'HR_ADMIN') return 0;
                if (role == 'SUPERVISOR') return 1;
                return 2; 
              }
              
              return getPriority(roleA).compareTo(getPriority(roleB));
           });
        }
      } catch (e) { print('Users fetch error: $e'); }

      // 2. Fetch Stats
      int employeesCount = 0;
      try {
         final stats = await _apiService.get('/dashboard/admin/stats');
         if (stats != null && stats is Map) {
            final val = stats['totalEmployees'];
            employeesCount = (val is int) ? val : int.tryParse(val.toString()) ?? 0;
         }
      } catch (e) { print('Stats error: $e'); }

      // 3. Fetch Pending Leaves
      int pendingLeaves = 0;
      try {
         final leaves = await _apiService.get('/leaves/pending');
         if (leaves is List) pendingLeaves = leaves.length;
      } catch (e) { print('Leaves error: $e'); }

      if (mounted) {
        setState(() {
          _users = usersData;
          _pendingLeavesCount = pendingLeaves;
          // Calculate role stats
          _adminCount = usersData.where((u) => _getRoleName(u).toUpperCase() == 'HR_ADMIN').length;
          _supervisorCount = usersData.where((u) => _getRoleName(u).toUpperCase() == 'SUPERVISOR').length;
          _employeeCount = usersData.where((u) => _getRoleName(u).toUpperCase() == 'EMPLOYEE' || _getRoleName(u).toUpperCase() == 'OPERATOR').length;

          _totalEmployees = employeesCount > 0 ? employeesCount : _employeeCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    } 
  }

  String _getRoleName(dynamic user) {
     try {
       if (user == null) return 'UNKNOWN';
       final role = user['role'];
       if (role == null) return 'UNKNOWN';
       if (role is Map) return role['name']?.toString() ?? 'UNKNOWN';
       return role.toString();
     } catch (e) { return 'UNKNOWN'; }
  }

  // --- Actions --- 
  Future<void> _deleteUser(String matricule) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Confirm Deletion', style: AppTypography.headerSmall),
          content: Text('Delete user $matricule?', style: AppTypography.bodyMedium),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true), 
                child: Text('Delete', style: TextStyle(color: AppColors.error))
            ),
          ],
        ),
      );
      if (confirm != true) return;
      try {
        await _apiService.delete('/users/$matricule');
        _loadDashboardData(); 
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
  }

  Future<void> _managePoints(Map<String, dynamic> user) async {
        final pointsController = TextEditingController();
        final descController = TextEditingController();
        int _currentPoints = user['pointsBalance'] ?? 0;
        bool _isAdding = true;

        await showDialog(
            context: context,
            builder: (ctx) => StatefulBuilder(
                builder: (context, setState) {
                    return AlertDialog(
                        title: Row(
                            children: [
                                Icon(Icons.stars, color: AppColors.secondary),
                                const SizedBox(width: 8),
                                Text('Manage Points', style: AppTypography.headerSmall),
                            ],
                        ),
                        content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('${user['fullName']}', style: AppTypography.headerSmall),
                                Text('Current Balance: $_currentPoints', style: AppTypography.bodyMedium.copyWith(color: Colors.grey[600])),
                                const SizedBox(height: 16),
                                Row(
                                    children: [
                                        Expanded(
                                            child: InkWell(
                                                onTap: () => setState(() => _isAdding = true),
                                                child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    decoration: BoxDecoration(
                                                        color: _isAdding ? AppColors.success.withOpacity(0.1) : Colors.transparent,
                                                        border: Border(bottom: BorderSide(color: _isAdding ? AppColors.success : Colors.transparent, width: 2)),
                                                    ),
                                                    child: Center(child: Text('Add Points', style: TextStyle(color: _isAdding ? AppColors.success : Colors.grey, fontWeight: FontWeight.bold))),
                                                ),
                                            ),
                                        ),
                                        Expanded(
                                            child: InkWell(
                                                onTap: () => setState(() => _isAdding = false),
                                                child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    decoration: BoxDecoration(
                                                        color: !_isAdding ? AppColors.error.withOpacity(0.1) : Colors.transparent,
                                                        border: Border(bottom: BorderSide(color: !_isAdding ? AppColors.error : Colors.transparent, width: 2)),
                                                    ),
                                                    child: Center(child: Text('Deduct Points', style: TextStyle(color: !_isAdding ? AppColors.error : Colors.grey, fontWeight: FontWeight.bold))),
                                                ),
                                            ),
                                        ),
                                    ],
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                    controller: pointsController, 
                                    decoration: InputDecoration(
                                        labelText: 'Points Amount', 
                                        prefixIcon: const Icon(Icons.confirmation_number_outlined),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ), 
                                    keyboardType: TextInputType.number
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                    controller: descController, 
                                    decoration: InputDecoration(
                                        labelText: 'Reason / Comment', 
                                        prefixIcon: const Icon(Icons.comment_outlined),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    )
                                ),
                            ],
                        ),
                        actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: _isAdding ? AppColors.success : AppColors.error),
                                onPressed: () async {
                                    if (pointsController.text.isEmpty || descController.text.isEmpty) {
                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                                         return;
                                    }
                                    try {
                                        final endpoint = _isAdding ? '/points/add' : '/points/deduct';
                                        await _apiService.post(endpoint, {
                                            'employeeId': user['id'],
                                            'points': int.parse(pointsController.text),
                                            'reason': descController.text,
                                        });
                                        if (mounted) {
                                            Navigator.pop(ctx);
                                            _loadDashboardData();
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isAdding ? 'Points added successfully' : 'Points deducted successfully')));
                                        }
                                    } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                }, 
                                child: Text(_isAdding ? 'Add Points' : 'Deduct Points')
                            ),
                        ],
                    );
                }
            ),
        );
  }

  Future<void> _importCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        
        // Show loading
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading file...')));
        }

        await _apiService.uploadFile('/users/import/csv', file);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import successful!')));
           _loadDashboardData();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Future<void> _addUser() async {
      final matriculeController = TextEditingController();
      final nameController = TextEditingController();
      final roleController = TextEditingController(text: 'EMPLOYEE');
      await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              title: Text('Add User', style: AppTypography.headerSmall),
              content: SingleChildScrollView(
                  child: Column(
                      children: [
                          TextField(controller: matriculeController, decoration: const InputDecoration(labelText: 'Matricule')),
                          const SizedBox(height: 12),
                          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                              value: 'EMPLOYEE',
                              items: ['HR_ADMIN', 'SUPERVISOR', 'EMPLOYEE'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                              onChanged: (v) => roleController.text = v!,
                              decoration: const InputDecoration(labelText: 'Role'),
                          ),
                      ],
                  )
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () async {
                          try {
                              await _apiService.post('/users', {
                                  'matricule': matriculeController.text,
                                  'fullName': nameController.text,
                                  'role': {'name': roleController.text}, 
                                  'password': 'password123',
                                  'pointsBalance': 0, 
                              });
                              if (mounted) { Navigator.pop(ctx); _loadDashboardData(); }
                          } catch (e) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                      },
                      child: const Text('Create')
                  )
              ],
          )
      );
  }

  @override
  Widget build(BuildContext context) {
    // Note: Wrapping in Theme to ensure Admin tokens apply
    return Theme(
      data: AppTheme.adminTheme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: const AppDrawer(userRole: 'HR_ADMIN'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 140.0,
                    pinned: true,
                    backgroundColor: AppColors.adminPrimary,
                    elevation: 0,
                    actions: [
                        IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadDashboardData),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async {
                               await _apiService.logout();
                               if (context.mounted) {
                                 Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                               }
                          },
                        ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 20, right: 20),
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('LEONI', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white, letterSpacing: 1.0)),
                              const SizedBox(width: 8),
                              Container(width: 1, height: 12, color: Colors.white54),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white24, width: 0.5),
                                ),
                                child: Text('HR ADMIN', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 8, color: Colors.white, letterSpacing: 0.5)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _adminName.isNotEmpty ? 'HR Administration – $_adminName' : 'HR Administration',
                            style: AppTypography.headerSmall.copyWith(color: Colors.white, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      background: Container(
                        color: AppColors.adminPrimary,
                        alignment: Alignment.centerRight,
                        // subtle corporate pattern or clean background
                      ),
                    ),
                  ),
                  
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.pagePadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatRow(),
                          const SizedBox(height: AppSpacing.xl),
                          
                          Text('Workforce Composition', style: AppTypography.headerSmall),
                          const SizedBox(height: AppSpacing.m),
                          _buildDistributionChart(),
                          
                          const SizedBox(height: AppSpacing.xl),
                          // Responsive Header Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Employee Management Overview', style: AppTypography.headerSmall),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _importCsv,
                                      icon: const Icon(Icons.upload_file, size: 18),
                                      label: const Text('Bulk Import', overflow: TextOverflow.ellipsis),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(color: AppColors.primary),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _addUser,
                                      icon: const Icon(Icons.person_add, size: 18),
                                      label: const Text('Register', overflow: TextOverflow.ellipsis),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                        ],
                      ),
                    ),
                  ),

                  // USER TABLE
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                    sliver: SliverToBoxAdapter(
                       child: Card(
                         elevation: 1,
                         child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                            columnSpacing: 20,
                            horizontalMargin: 12,
                            columns: const [
                              DataColumn(label: Text('Matricule')),
                              DataColumn(label: Text('Name/Role')),
                              DataColumn(label: Text('Points')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _users.map((user) {
                               final role = _getRoleName(user);
                               return DataRow(cells: [
                                  DataCell(Text(user['matricule'] ?? '', style: AppTypography.bodyMedium)),
                                  DataCell(Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(user['fullName'] ?? '-', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                      Text(role, style: AppTypography.label),
                                    ],
                                  )),
                                  DataCell(
                                      (role == 'HR_ADMIN' || role == 'SUPERVISOR') 
                                      ? const Text('') 
                                      : Text((user['pointsBalance'] ?? 0).toString(), style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary))
                                  ),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.stars, size: 20, color: AppColors.secondary),
                                        onPressed: () => _managePoints(user),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                        onPressed: () => _deleteUser(user['matricule']),
                                      ),
                                    ],
                                  )),
                               ]);
                            }).toList(),
                         ),
                       ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              ),
      ),
    );
  }

  Widget _buildStatRow() {
    return Row(
      children: [
        Expanded(child: _StatTile(label: 'Total Personnel', value: _users.length.toString(), icon: Icons.people_alt)),
        const SizedBox(width: AppSpacing.m),
        Expanded(child: _StatTile(label: 'Approvals Pending', value: _pendingLeavesCount.toString(), icon: Icons.pending_actions, color: AppColors.warning)),
      ],
    );
  }

  Widget _buildDistributionChart() {
    if (_users.isEmpty) {
      return const SizedBox(height: 150, child: Center(child: Text('No data')));
    }
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                    PieChartSectionData(color: AppColors.employeePrimary, value: _employeeCount.toDouble(), title: '', radius: 50),
                    PieChartSectionData(color: AppColors.adminPrimary, value: _supervisorCount.toDouble(), title: '', radius: 50),
                    PieChartSectionData(color: Colors.grey, value: _adminCount.toDouble(), title: '', radius: 50),
                ],
              ),
            ),
          ),
          Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               _LegendItem(color: AppColors.employeePrimary, text: 'Employees ($_employeeCount)'),
               _LegendItem(color: AppColors.adminPrimary, text: 'Supervisors ($_supervisorCount)'),
               _LegendItem(color: Colors.grey, text: 'Admins ($_adminCount)'),
             ],
          )
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatTile({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
     return Container(
       padding: const EdgeInsets.all(AppSpacing.m),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: Colors.grey.shade200),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Icon(icon, color: color ?? AppColors.primary, size: 20),
                 Text(value, style: AppTypography.headerMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.label),
         ],
       ),
     );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
