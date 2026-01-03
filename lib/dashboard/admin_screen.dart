
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../auth/login_screen.dart';
import 'audit_log_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadDashboardData();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _apiService.get('/auth/me');
      print('DEBUG: Profile response: $user');
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
    print('DEBUG: Starting _loadDashboardData');
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Users
      print('DEBUG: Fetching /users');
      List<dynamic> usersData = [];
      try {
        final res = await _apiService.get('/users');
        if (res is List) {
           usersData = res;
           print('DEBUG: Fetched ${usersData.length} users');
        } else {
           print('DEBUG: Users response is not a list: $res');
        }
      } catch (e) { print('DEBUG: Users fetch error: $e'); }

      // 2. Fetch Stats
      print('DEBUG: Fetching /dashboard/admin/stats');
      int employeesCount = 0;
      try {
         final stats = await _apiService.get('/dashboard/admin/stats');
         print('DEBUG: Stats response: $stats');
         if (stats != null && stats is Map) {
            final val = stats['totalEmployees'];
            print('DEBUG: totalEmployees raw: $val (${val.runtimeType})');
            employeesCount = (val is int) ? val : int.tryParse(val.toString()) ?? 0;
         }
      } catch (e) { print('DEBUG: Stats error: $e'); }

      // 3. Fetch Pending Leaves
      print('DEBUG: Fetching /leaves/pending');
      int pendingLeaves = 0;
      try {
         final leaves = await _apiService.get('/leaves/pending');
         if (leaves is List) pendingLeaves = leaves.length;
      } catch (e) { print('DEBUG: Leaves error: $e'); }

      if (mounted) {
        setState(() {
          _users = usersData;
          _pendingLeavesCount = pendingLeaves;
          // Calculate stats carefully
          try {
             _totalEmployees = employeesCount > 0 
                ? employeesCount 
                : usersData.where((u) {
                    final r = _getRoleName(u).toUpperCase();
                    return r == 'EMPLOYEE' || r == 'OPERATOR';
                  }).length;
          } catch (e) {
             print('DEBUG: Error calculating employee count: $e');
             _totalEmployees = 0;
          }
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('DEBUG: FATAL Error loading data: $e');
      print(stack);
      if (mounted) setState(() => _isLoading = false);
    } 
  }

  String _getRoleName(dynamic user) {
     try {
       if (user == null) return 'UNKNOWN';
       final role = user['role'];
       if (role == null) return 'UNKNOWN';
       
       if (role is Map) {
          final name = role['name'];
          return name?.toString() ?? 'UNKNOWN';
       }
       return role.toString();
     } catch (e) {
       print('DEBUG: Error in _getRoleName: $e');
       return 'UNKNOWN';
     }
  }

  // --- Actions --- 
  Future<void> _deleteUser(String matricule) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Delete user $matricule?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
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

  Future<void> _adjustPoints(String matricule) async {
        final pointsController = TextEditingController();
        final descController = TextEditingController();
        final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
            title: const Text('Adjust Points'),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                TextField(controller: pointsController, decoration: const InputDecoration(labelText: 'Points (+/-)'), keyboardType: const TextInputType.numberWithOptions(signed: true)),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Reason')),
                ],
            ),
            actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () { if (pointsController.text.isNotEmpty) Navigator.pop(ctx, true); }, child: const Text('Save')),
            ],
            ),
        );
        if (confirm != true) return;
        try {
            await _apiService.patch('/users/$matricule/points', {
                'points': int.parse(pointsController.text),
                'type': 'MANUAL_ADJUST',
                'description': descController.text.isEmpty ? 'Admin Adjustment' : descController.text,
            });
            _loadDashboardData();
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Points updated')));
        } catch (e) {
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
  }

  Future<void> _addUser() async {
      final matriculeController = TextEditingController();
      final nameController = TextEditingController();
      final roleController = TextEditingController(text: 'EMPLOYEE');
      await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              title: const Text('Add User'),
              content: SingleChildScrollView(
                  child: Column(
                      children: [
                          TextField(controller: matriculeController, decoration: const InputDecoration(labelText: 'Matricule')),
                          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
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

  Future<void> _importCsv() async {
    try {
        // FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'xlsx']);
        // if (result != null) {
        //   setState(() => _isLoading = true);
        //   File file = File(result.files.single.path!);
        //   await _apiService.uploadFile('/users/import/csv', file);
        //   _loadDashboardData();
        //   if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import successful')));
        // }
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV Import not yet implemented')));
    } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
        if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xFF003366),
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
                    centerTitle: true,
                    background: Container(
                      color: const Color(0xFF003366),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white,
                              child: Text(
                                _adminName.isNotEmpty ? _adminName[0].toUpperCase() : 'HR',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                              ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _adminName.isNotEmpty ? _adminName : 'HR Admin',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('HR ADMINISTRATOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // OVERVIEW SECTION
                        Text('Overview', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0B2C5F))),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                             Expanded(child: _buildStatCard('Employees', '$_totalEmployees', Icons.people_outline, Colors.blue)),
                             const SizedBox(width: 12),
                             Expanded(child: _buildStatCard('Pending Leaves', '$_pendingLeavesCount', Icons.calendar_today, Colors.redAccent)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                             Expanded(child: _buildStatCard('Alerts', '$_alertsCount', Icons.notifications_none, Colors.grey)),
                             const SizedBox(width: 12),
                             const Spacer(), // Placeholder for 4th card if needed layout balance
                          ],
                        ),

                        // CONTROL CENTER SECTION
                        const SizedBox(height: 32),
                        Text('Control Center', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0B2C5F))),
                        const SizedBox(height: 16),
                        Row(
                           children: [
                              Expanded(child: _buildControlCard('Permissions', Icons.settings, () {
                                  // Navigate to user list section
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manage permissions via User List below')));
                              })),
                              const SizedBox(width: 12),
                              Expanded(child: _buildControlCard('Audit Logs', Icons.history_edu, () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogScreen()));
                              })),
                              const SizedBox(width: 12),
                              Expanded(child: _buildControlCard('Mod. Points', Icons.card_giftcard, () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a user below to modify points')));
                              })),
                           ],
                        ),
                        
                        const SizedBox(height: 24),
                        // BOTTOM ACTIONS
                        Text('User Actions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0B2C5F))),
                        const SizedBox(height: 16),
                        Row(
                             children: [
                                 Expanded(
                                     child: ElevatedButton.icon(
                                         onPressed: _addUser,
                                         icon: const Icon(Icons.person_add, size: 20),
                                         label: const Text('ADD USER'),
                                         style: ElevatedButton.styleFrom(
                                             padding: const EdgeInsets.symmetric(vertical: 16),
                                             backgroundColor: const Color(0xFF003366),
                                             foregroundColor: Colors.white,
                                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                         ),
                                     )
                                 ),
                                 const SizedBox(width: 12),
                                 Expanded(
                                     child: OutlinedButton.icon(
                                         onPressed: _importCsv,
                                         icon: const Icon(Icons.upload_file, size: 20),
                                         label: const Text('IMPORT CSV'),
                                         style: OutlinedButton.styleFrom(
                                             padding: const EdgeInsets.symmetric(vertical: 16),
                                             foregroundColor: const Color(0xFF003366),
                                             side: const BorderSide(color: Color(0xFF003366), width: 1.5),
                                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                         ),
                                     )
                                 ),
                             ],
                         ),

                        const SizedBox(height: 32),
                        // USER LIST HEADER
                        Text('All Users (${_users.length})', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0B2C5F))),
                      ],
                    ),
                  ),
                ),

                // USER LIST
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                        final user = _users[index];
                        return _buildUserTile(user);
                    },
                    childCount: _users.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 12),
                  Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0B2C5F))),
                  Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
              ],
          ),
      );
  }

  Widget _buildControlCard(String title, IconData icon, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(icon, color: const Color(0xFF003366), size: 24),
                    const SizedBox(height: 8),
                    Text(title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0B2C5F))),
                ],
            ),
        ),
      );
  }

  Widget _buildUserTile(dynamic user) {
     final role = _getRoleName(user);
     return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)]),
        child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
                backgroundColor: const Color(0xFFE3F2FD),
                child: Text(user['fullName'] != null ? user['fullName'][0].toUpperCase() : 'U', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
            ),
            title: Text(user['fullName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('${user['matricule']} • $role\nPoints: ${user['pointsBalance'] ?? 0}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _adjustPoints(user['matricule']),
                    tooltip: 'Adjust Points',
                ),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUser(user['matricule']),
                    tooltip: 'Delete User',
                ),
              ],
            ),
        ),
     );
  }
}
