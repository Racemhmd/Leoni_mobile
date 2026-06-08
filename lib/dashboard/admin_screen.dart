import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../auth/login_screen.dart';
import 'audit_log_screen.dart';
import '../theme/design_system.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

// ── Point categories mirroring backend PointReason enum ──────────────────────
const _kEarningCategories = <String, int>{
  'BEST_EMPLOYEE': 20,
  'BEST_TEAM': 5,
  'AIP_PLUS': 5,
  'CIP': 5,
  'PRESENCE_MONTH': 2,
  'PLANT_MANAGER_MOTIVATION': 5,
};

const _kPenaltyCategories = <String, double>{
  'ABSENCE_SHORT': 5,
  'ABSENCE_LONG': 10,
  'UNPLANNED_ABSENCE': 5,
  'DELAY': 0.5,
  'DISCIPLINARY_SANCTION': 5,
};

const _kAbsenceCategories = {'ABSENCE_SHORT', 'ABSENCE_LONG', 'UNPLANNED_ABSENCE'};

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

  // KPI values
  int _totalEmployees = 0;
  int _pendingLeavesCount = 0;
  double _pointsThisMonth = 0;
  int _unplannedAbsencesMonth = 0;
  int _liquidationDaysLeft = -1;
  String _liquidationName = '';

  int _employeeCount = 0;
  int _supervisorCount = 0;
  int _adminCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadProfile(),
        _loadDashboardData(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _apiService.get('/auth/me');
      if (mounted) {
        setState(() => _adminName = user['fullName']?.toString() ?? 'HR Admin');
      }
    } catch (_) {}
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        _apiService.get('/users').catchError((_) => <dynamic>[]),
        _apiService
            .get('/dashboard/admin/stats')
            .catchError((_) => <String, dynamic>{}),
        _apiService
            .get('/leaves/pending')
            .catchError((_) => <dynamic>[]),
        _apiService
            .get('/liquidation/next')
            .catchError((_) => <String, dynamic>{}),
      ]);

      final usersData = (results[0] is List) ? results[0] as List<dynamic> : <dynamic>[];
      final stats = results[1] as Map<String, dynamic>;
      final leaves = (results[2] is List) ? results[2] as List<dynamic> : <dynamic>[];
      final liquidation = results[3] as Map<String, dynamic>;

      usersData.sort((a, b) => _rolePriority(_getRoleName(a))
          .compareTo(_rolePriority(_getRoleName(b))));

      if (mounted) {
        setState(() {
          _users = usersData;
          _pendingLeavesCount = leaves.length;
          _adminCount = usersData
              .where((u) => _getRoleName(u).toUpperCase() == 'HR_ADMIN')
              .length;
          _supervisorCount = usersData
              .where((u) => _getRoleName(u).toUpperCase() == 'SUPERVISOR')
              .length;
          _employeeCount = usersData
              .where((u) =>
                  _getRoleName(u).toUpperCase() == 'EMPLOYEE' ||
                  _getRoleName(u).toUpperCase() == 'OPERATOR')
              .length;
          _totalEmployees =
              (stats['totalEmployees'] as num?)?.toInt() ?? _employeeCount;
          _pointsThisMonth =
              (stats['totalPointsThisMonth'] as num?)?.toDouble() ?? 0;
          _unplannedAbsencesMonth =
              (stats['unplannedAbsencesMonth'] as num?)?.toInt() ?? 0;
          _liquidationDaysLeft =
              (liquidation['daysRemaining'] as num?)?.toInt() ?? -1;
          _liquidationName = liquidation['shortName'] as String? ?? '';
        });
      }
    } catch (e) {
      debugPrint('Admin load error: $e');
    }
  }

  int _rolePriority(String role) {
    switch (role.toUpperCase()) {
      case 'HR_ADMIN':
        return 0;
      case 'SUPERVISOR':
        return 1;
      default:
        return 2;
    }
  }

  String _getRoleName(dynamic user) {
    try {
      final role = user['role'];
      if (role == null) return 'UNKNOWN';
      if (role is Map) return role['name']?.toString() ?? 'UNKNOWN';
      return role.toString();
    } catch (_) {
      return 'UNKNOWN';
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _deleteUser(String matricule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'employé'),
        content: Text('Supprimer $matricule définitivement ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _apiService.delete('/users/$matricule');
      _loadDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employé supprimé')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _managePoints(Map<String, dynamic> user) async {
    // state managed inside StatefulBuilder
    String _selectedCategory = _kEarningCategories.keys.first;
    bool _isAdding = true;
    int _absenceDays = 1;
    final Set<int> _selectedUserIds = {user['id'] as int};
    bool _massMode = false;
    File? _justificatif;
    final _descController = TextEditingController();

    double _computedPoints() {
      if (_isAdding) {
        return (_kEarningCategories[_selectedCategory] ?? 0).toDouble();
      } else {
        if (_kAbsenceCategories.contains(_selectedCategory)) {
          return _absenceDays <= 2 ? 5 : 10;
        }
        return _kPenaltyCategories[_selectedCategory] ?? 0;
      }
    }

    String _resolvedReason() {
      if (_isAdding) return _selectedCategory;
      if (_kAbsenceCategories.contains(_selectedCategory)) {
        return _absenceDays <= 2 ? 'ABSENCE_SHORT' : 'ABSENCE_LONG';
      }
      return _selectedCategory;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          final allEmployees = _users
              .where((u) =>
                  _getRoleName(u).toUpperCase() == 'EMPLOYEE' ||
                  _getRoleName(u).toUpperCase() == 'OPERATOR')
              .toList();

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.bottomSheet,
            ),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.m,
              AppSpacing.l,
              AppSpacing.l + MediaQuery.of(ctx2).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin:
                          const EdgeInsets.only(bottom: AppSpacing.l),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Gestion des points', style: AppTypography.headerMedium),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    _massMode
                        ? '${_selectedUserIds.length} employé(s) sélectionné(s)'
                        : user['fullName'] as String? ?? '',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Add / Deduct tabs
                  Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Attribuer',
                          active: _isAdding,
                          color: AppColors.success,
                          onTap: () => setS(() {
                            _isAdding = true;
                            _selectedCategory =
                                _kEarningCategories.keys.first;
                          }),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: _TabButton(
                          label: 'Déduire',
                          active: !_isAdding,
                          color: AppColors.error,
                          onTap: () => setS(() {
                            _isAdding = false;
                            _selectedCategory =
                                _kPenaltyCategories.keys.first;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.m)),
                    ),
                    items: (_isAdding
                            ? _kEarningCategories.keys
                            : _kPenaltyCategories.keys)
                        .map((k) => DropdownMenuItem(
                            value: k,
                            child: Text(
                                k.replaceAll('_', ' '),
                                style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setS(() => _selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Absence days (if absence category)
                  if (!_isAdding &&
                      _kAbsenceCategories.contains(_selectedCategory))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nombre de jours',
                            style: AppTypography.bodySmall),
                        const SizedBox(height: AppSpacing.s),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => setS(() {
                                if (_absenceDays > 1) _absenceDays--;
                              }),
                            ),
                            Text('$_absenceDays',
                                style: AppTypography.headerSmall),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  setS(() => _absenceDays++),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(
                                    AppRadius.full),
                              ),
                              child: Text(
                                _absenceDays <= 2
                                    ? 'SHORT (−5 pts)'
                                    : 'LONG (−10 pts)',
                                style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),
                      ],
                    ),

                  // Points preview
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: _isAdding
                          ? AppColors.successLight
                          : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppRadius.m),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Points',
                            style: AppTypography.bodySmall),
                        Text(
                          '${_isAdding ? '+' : '-'}${_computedPoints()} pts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isAdding
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Description
                  TextField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Commentaire (optionnel)',
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.m)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Justificatif upload (absence categories)
                  if (!_isAdding &&
                      _kAbsenceCategories.contains(_selectedCategory))
                    OutlinedButton.icon(
                      icon: Icon(
                        _justificatif == null
                            ? Icons.upload_file
                            : Icons.check_circle_outline,
                        size: 18,
                        color: _justificatif == null
                            ? AppColors.primary
                            : AppColors.success,
                      ),
                      label: Text(
                        _justificatif == null
                            ? 'Joindre un justificatif'
                            : 'Justificatif joint',
                        style: TextStyle(
                          color: _justificatif == null
                              ? AppColors.primary
                              : AppColors.success,
                        ),
                      ),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: [
                            'pdf',
                            'jpg',
                            'jpeg',
                            'png'
                          ],
                        );
                        if (result != null) {
                          setS(() => _justificatif =
                              File(result.files.single.path!));
                        }
                      },
                    ),

                  // Mass assignment toggle
                  const SizedBox(height: AppSpacing.m),
                  SwitchListTile(
                    value: _massMode,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Attribution en masse',
                        style: AppTypography.bodyMedium),
                    activeColor: AppColors.primary,
                    onChanged: (v) => setS(() {
                      _massMode = v;
                      if (!v) {
                        _selectedUserIds
                          ..clear()
                          ..add(user['id'] as int);
                      }
                    }),
                  ),

                  if (_massMode) ...[
                    const SizedBox(height: AppSpacing.s),
                    Text('Sélectionner les employés :',
                        style: AppTypography.bodySmall),
                    const SizedBox(height: AppSpacing.s),
                    ...allEmployees.map((u) {
                      final uid = u['id'] as int;
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(u['fullName'] ?? '',
                            style: AppTypography.bodyMedium),
                        subtitle: Text(u['matricule'] ?? '',
                            style: AppTypography.caption),
                        value: _selectedUserIds.contains(uid),
                        activeColor: AppColors.primary,
                        onChanged: (v) => setS(() {
                          if (v == true) {
                            _selectedUserIds.add(uid);
                          } else {
                            _selectedUserIds.remove(uid);
                          }
                        }),
                      );
                    }),
                    const SizedBox(height: AppSpacing.m),
                  ],

                  // Confirm button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isAdding ? AppColors.success : AppColors.error,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    onPressed: () async {
                      if (_selectedUserIds.isEmpty) return;
                      try {
                        final endpoint =
                            _isAdding ? '/points/add' : '/points/deduct';
                        final pts = _computedPoints();
                        final reason = _resolvedReason();
                        final desc = _descController.text.isNotEmpty
                            ? _descController.text
                            : reason.replaceAll('_', ' ');

                        for (final uid in _selectedUserIds) {
                          await _apiService.post(endpoint, {
                            'employeeId': uid,
                            'points': pts,
                            'reason': reason,
                            'description': desc,
                          });
                        }

                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadDashboardData();
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isAdding
                                  ? 'Points attribués à ${_selectedUserIds.length} employé(s)'
                                  : 'Points déduits'),
                              backgroundColor: _isAdding
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(ctx2).showSnackBar(
                            SnackBar(content: Text('Erreur: $e')));
                      }
                    },
                    child: Text(_isAdding
                        ? 'Attribuer les points'
                        : 'Déduire les points'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );
      if (result == null) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import en cours…')));
      }
      await _apiService.uploadFile(
          '/users/import/csv', File(result.files.single.path!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import réussi !')));
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur import: $e')));
      }
    }
  }

  Future<void> _addUser() async {
    final matriculeC = TextEditingController();
    final nameC = TextEditingController();
    String roleValue = 'EMPLOYEE';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => AlertDialog(
          title: Text('Nouvel employé', style: AppTypography.headerSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: matriculeC,
                  decoration: const InputDecoration(labelText: 'Matricule')),
              const SizedBox(height: 12),
              TextField(
                  controller: nameC,
                  decoration:
                      const InputDecoration(labelText: 'Nom complet')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: roleValue,
                items: ['HR_ADMIN', 'SUPERVISOR', 'EMPLOYEE']
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setS(() => roleValue = v!),
                decoration: const InputDecoration(labelText: 'Rôle'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.post('/users', {
                    'matricule': matriculeC.text.trim(),
                    'fullName': nameC.text.trim(),
                    'role': {'name': roleValue},
                    'password': 'password123',
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadDashboardData();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(ctx2)
                      .showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.adminTheme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: const AppDrawer(userRole: 'HR_ADMIN'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // ── App Bar ────────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 130,
                    pinned: true,
                    backgroundColor: AppColors.adminPrimary,
                    elevation: 0,
                    actions: [
                      IconButton(
                          icon: const Icon(Icons.history, color: Colors.white),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AuditLogScreen()))),
                      IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _loadAll),
                      IconButton(
                          icon:
                              const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async {
                            await _apiService.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()));
                            }
                          }),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LEONI · HR ADMIN',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  letterSpacing: 1.2)),
                          Text(
                            _adminName.isNotEmpty
                                ? _adminName
                                : 'HR Administration',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      background:
                          Container(color: AppColors.adminPrimary),
                    ),
                  ),

                  SliverPadding(
                    padding: AppSpacing.pagePadding,
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── 4 KPI cards ──────────────────────────────────
                        _buildKpiGrid(),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Distribution chart ───────────────────────────
                        Text('Répartition du personnel',
                            style: AppTypography.headerSmall),
                        const SizedBox(height: AppSpacing.m),
                        _buildDistributionChart(),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Action bar ───────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _importCsv,
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Import CSV/Excel'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _addUser,
                                icon: const Icon(Icons.person_add, size: 18),
                                label: const Text('Enregistrer'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),
                      ]),
                    ),
                  ),

                  // ── User table ────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m),
                    sliver: SliverToBoxAdapter(
                      child: Card(
                        elevation: 1,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                              Colors.grey.shade100),
                          columnSpacing: 20,
                          horizontalMargin: 12,
                          columns: const [
                            DataColumn(label: Text('Matricule')),
                            DataColumn(label: Text('Nom / Rôle')),
                            DataColumn(label: Text('Pts')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _users.map((user) {
                            final role = _getRoleName(user);
                            return DataRow(cells: [
                              DataCell(Text(user['matricule'] ?? '',
                                  style: AppTypography.bodyMedium)),
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    user['fullName'] ?? '-',
                                    style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(role, style: AppTypography.label),
                                ],
                              )),
                              DataCell(
                                (role == 'HR_ADMIN' ||
                                        role == 'SUPERVISOR')
                                    ? const Text('')
                                    : Text(
                                        (user['pointsBalance'] ?? 0)
                                            .toString(),
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        )),
                              ),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.stars,
                                        size: 20,
                                        color: AppColors.secondary),
                                    onPressed: () => _managePoints(
                                        Map<String, dynamic>.from(
                                            user as Map)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: AppColors.error),
                                    onPressed: () =>
                                        _deleteUser(user['matricule']),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxl)),
                ],
              ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.m,
      crossAxisSpacing: AppSpacing.m,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _KpiCard(
          icon: Icons.people_alt_outlined,
          label: 'Employés actifs',
          value: _totalEmployees.toString(),
          color: AppColors.primary,
        ),
        _KpiCard(
          icon: Icons.star_outline_rounded,
          label: 'Points ce mois',
          value: _pointsThisMonth.toStringAsFixed(0),
          color: AppColors.success,
        ),
        _KpiCard(
          icon: Icons.event_busy_outlined,
          label: 'Absences imprévues',
          value: _unplannedAbsencesMonth.toString(),
          color: AppColors.warning,
        ),
        _KpiCard(
          icon: Icons.account_balance_wallet_outlined,
          label: _liquidationDaysLeft >= 0
              ? 'Liquidation $_liquidationName'
              : 'Prochaine liquidation',
          value: _liquidationDaysLeft >= 0
              ? '$_liquidationDaysLeft j.'
              : '—',
          color: AppColors.info,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildDistributionChart() {
    if (_users.isEmpty) {
      return const SizedBox(
          height: 150, child: Center(child: Text('Aucune donnée')));
    }
    return Container(
      height: 180,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: [
                  PieChartSectionData(
                      color: AppColors.employeePrimary,
                      value: _employeeCount.toDouble(),
                      title: '',
                      radius: 44),
                  PieChartSectionData(
                      color: AppColors.adminPrimary,
                      value: _supervisorCount.toDouble(),
                      title: '',
                      radius: 44),
                  PieChartSectionData(
                      color: Colors.grey,
                      value: _adminCount.toDouble(),
                      title: '',
                      radius: 44),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                  color: AppColors.employeePrimary,
                  text: 'Employés ($_employeeCount)'),
              _LegendItem(
                  color: AppColors.adminPrimary,
                  text: 'Superviseurs ($_supervisorCount)'),
              _LegendItem(
                  color: Colors.grey, text: 'HR Admin ($_adminCount)'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTypography.headerMedium
                      .copyWith(color: color, fontSize: 22)),
              Text(label,
                  style: AppTypography.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab button ────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(
            color: active ? color : AppColors.divider,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? color : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
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
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
