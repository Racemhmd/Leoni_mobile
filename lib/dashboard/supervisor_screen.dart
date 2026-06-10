import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../auth/login_screen.dart';
import '../theme/design_system.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../screens/hr_kpi_dashboard_screen.dart';
import '../screens/sanctions_dashboard_screen.dart';
import '../screens/employee_sanctions_history_screen.dart';

class SupervisorScreen extends StatefulWidget {
  const SupervisorScreen({super.key});

  @override
  State<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<SupervisorScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();

  late final TabController _tabController;

  bool _isLoading = true;
  String _supervisorName = '';
  List<dynamic> _pendingLeaves = [];
  List<dynamic> _allLeaves    = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.get('/auth/me'),
        _apiService.get('/leaves/supervisor'),
        _apiService.get('/leaves/team').catchError((_) => <dynamic>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _supervisorName = (results[0] as Map<String, dynamic>)['fullName'] ?? 'Superviseur';
        _pendingLeaves  = (results[1] as List<dynamic>?) ?? [];
        _allLeaves      = (results[2] as List<dynamic>?) ?? [];
        _isLoading      = false;
      });
    } catch (e) {
      debugPrint('SupervisorScreen error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Decision dialog ────────────────────────────────────────────────────────

  Future<void> _showDecisionDialog(Map<String, dynamic> leave, bool approve) async {
    final commentCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          approve ? 'Approuver la demande' : 'Refuser la demande',
          style: AppTypography.headerSmall,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employé : ${_fullName(leave)}',
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${_leaveTypeLabel(leave['leaveType'])} · ${_fmt(leave['startDate'])} → ${_fmt(leave['endDate'])}',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: approve ? 'Commentaire (optionnel)' : 'Motif du refus',
                hintText: approve ? 'Ajouter une note...' : 'Veuillez indiquer la raison...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: approve ? AppColors.success : AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(approve ? 'Approuver' : 'Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _apiService.patch(
        '/leaves/${leave['id']}/supervisor-decision',
        {
          'action': approve ? 'APPROVE' : 'REJECT',
          if (commentCtrl.text.trim().isNotEmpty) 'comment': commentCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve ? 'Demande approuvée' : 'Demande refusée'),
        backgroundColor: approve ? AppColors.success : AppColors.error,
      ));
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fullName(Map<String, dynamic> leave) {
    final emp = leave['employee'] as Map<String, dynamic>?;
    if (emp == null) return 'Employé #${leave['employeeId']}';
    return emp['fullName'] ?? '${emp['firstName'] ?? ''} ${emp['lastName'] ?? ''}'.trim();
  }

  String _matricule(Map<String, dynamic> leave) =>
      (leave['employee'] as Map<String, dynamic>?)?['matricule'] ?? '';

  String _group(Map<String, dynamic> leave) =>
      (leave['employee'] as Map<String, dynamic>?)?['group'] ??
      (leave['employee'] as Map<String, dynamic>?)?['productionGroup'] ?? '';

  String _leaveTypeLabel(String? type) {
    switch (type) {
      case 'ANNUAL_LEAVE':         return 'Congé Annuel';
      case 'AUTHORIZED_ABSENCE':   return 'Absence Autorisée';
      case 'INSUFFICIENT_BALANCE': return 'Solde Insuffisant';
      default:                     return type ?? '-';
    }
  }

  String _fmt(String? raw) {
    if (raw == null) return '-';
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw;
    }
  }

  int _days(Map<String, dynamic> leave) {
    try {
      final s = DateTime.parse(leave['startDate']);
      final e = DateTime.parse(leave['endDate']);
      return e.difference(s).inDays + 1;
    } catch (_) {
      return 0;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'PENDING_SUPERVISOR':     return AppColors.warning;
      case 'APPROVED_BY_SUPERVISOR': return AppColors.primary;
      case 'REJECTED_BY_SUPERVISOR': return AppColors.error;
      case 'APPROVED_BY_HR':         return AppColors.success;
      case 'REJECTED_BY_HR':         return AppColors.error;
      default:                       return AppColors.textSecondary;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'PENDING_SUPERVISOR':     return 'En attente';
      case 'APPROVED_BY_SUPERVISOR': return 'Approuvé (sup.)';
      case 'REJECTED_BY_SUPERVISOR': return 'Refusé (sup.)';
      case 'APPROVED_BY_HR':         return 'Approuvé (RH)';
      case 'REJECTED_BY_HR':         return 'Refusé (RH)';
      default:                       return status ?? '-';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.adminTheme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: const AppDrawer(userRole: 'SUPERVISOR'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : NestedScrollView(
                headerSliverBuilder: (ctx, _) => [_buildSliverAppBar()],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingTab(),
                    _buildHistoryTab(),
                  ],
                ),
              ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: const Color(0xFF0F1628),
      surfaceTintColor: Colors.transparent,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white70, size: 22),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
          onPressed: _loadData,
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
          onPressed: () async {
            await _apiService.logout();
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        title: null,
        background: _buildHeader(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _buildTabBar(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF0F1E38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Supervision',
                style: AppTypography.headerSmall.copyWith(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _supervisorName,
                style: AppTypography.headerMedium.copyWith(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 16),
              // Quick-access row
              Row(
                children: [
                  Expanded(
                    child: _QuickCard(
                      icon: Icons.analytics_outlined,
                      label: 'KPI Dashboard',
                      color: AppColors.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HrKpiDashboardScreen(userRole: 'SUPERVISOR'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickCard(
                      icon: Icons.security_outlined,
                      label: 'Sanctions',
                      color: AppColors.warning,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SanctionsDashboardScreen(userRole: 'SUPERVISOR'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickCard(
                      icon: Icons.person_search_outlined,
                      label: 'Par employé',
                      color: AppColors.secondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmployeeSanctionsHistoryScreen(userRole: 'SUPERVISOR'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF0F1628),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.white54,
        labelStyle: AppTypography.label.copyWith(fontSize: 13),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pending_actions_outlined, size: 16),
                const SizedBox(width: 6),
                const Text('En attente'),
                if (_pendingLeaves.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _CountBadge(count: _pendingLeaves.length),
                ],
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_outlined, size: 16),
                SizedBox(width: 6),
                Text('Historique'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab: pending ───────────────────────────────────────────────────────────

  Widget _buildPendingTab() {
    if (_pendingLeaves.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_outline,
        message: 'Aucune demande en attente',
        color: AppColors.success,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: _pendingLeaves.length,
        itemBuilder: (_, i) {
          final leave = _pendingLeaves[i] as Map<String, dynamic>;
          return _PendingCard(
            leave: leave,
            fullName:   _fullName(leave),
            matricule:  _matricule(leave),
            group:      _group(leave),
            leaveLabel: _leaveTypeLabel(leave['leaveType']),
            startDate:  _fmt(leave['startDate']),
            endDate:    _fmt(leave['endDate']),
            days:       _days(leave),
            reason:     leave['reason'] ?? '',
            onApprove:  () => _showDecisionDialog(leave, true),
            onReject:   () => _showDecisionDialog(leave, false),
          );
        },
      ),
    );
  }

  // ── Tab: history ───────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    if (_allLeaves.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        message: 'Aucune demande dans l\'historique',
        color: AppColors.textSecondary,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: _allLeaves.length,
        itemBuilder: (_, i) {
          final leave = _allLeaves[i] as Map<String, dynamic>;
          final status = leave['status'] as String?;
          final isPending = status == 'PENDING_SUPERVISOR';
          return _HistoryRow(
            fullName:   _fullName(leave),
            matricule:  _matricule(leave),
            group:      _group(leave),
            leaveType:  _leaveTypeLabel(leave['leaveType']),
            startDate:  _fmt(leave['startDate']),
            endDate:    _fmt(leave['endDate']),
            status:     _statusLabel(status),
            statusColor: _statusColor(status),
            // Allow approve/reject from history only if still pending
            onApprove:  isPending ? () => _showDecisionDialog(leave, true)  : null,
            onReject:   isPending ? () => _showDecisionDialog(leave, false) : null,
          );
        },
      ),
    );
  }
}

// ── Quick access card ──────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData    icon;
  final String      label;
  final Color       color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Count badge ────────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String   message;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: color, fontSize: 15)),
        ],
      ),
    );
  }
}

// ── Pending leave card (with approve/reject) ───────────────────────────────────

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.leave,
    required this.fullName,
    required this.matricule,
    required this.group,
    required this.leaveLabel,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> leave;
  final String       fullName;
  final String       matricule;
  final String       group;
  final String       leaveLabel;
  final String       startDate;
  final String       endDate;
  final int          days;
  final String       reason;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName,
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          if (matricule.isNotEmpty)
                            Text('Mat. $matricule',
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary)),
                          if (matricule.isNotEmpty && group.isNotEmpty)
                            Text(' · ',
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary)),
                          if (group.isNotEmpty)
                            Text(group,
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                _TypeBadge(label: leaveLabel),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Dates + duration
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text('$startDate → $endDate', style: AppTypography.bodySmall),
                const Spacer(),
                _DaysBadge(days: days),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      reason,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approuver'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── History row (read-only, with optional action buttons for still-pending) ─────

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.fullName,
    required this.matricule,
    required this.group,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.statusColor,
    this.onApprove,
    this.onReject,
  });

  final String        fullName;
  final String        matricule;
  final String        group;
  final String        leaveType;
  final String        startDate;
  final String        endDate;
  final String        status;
  final Color         statusColor;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName,
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        [if (matricule.isNotEmpty) 'Mat. $matricule', if (group.isNotEmpty) group]
                            .join(' · '),
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('$startDate → $endDate', style: AppTypography.bodySmall),
                const SizedBox(width: 8),
                Text('· $leaveType',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            // Show action buttons only if still pending
            if (onApprove != null && onReject != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      child: const Text('Refuser', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      child: const Text('Approuver', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _DaysBadge extends StatelessWidget {
  const _DaysBadge({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$days j',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
