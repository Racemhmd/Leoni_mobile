import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/points_service.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';
import '../services/liquidation_service.dart';
import '../auth/login_screen.dart';
import '../theme/design_system.dart';
import '../widgets/points_balance_card.dart';
import '../widgets/transaction_item.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import '../widgets/notification_bell.dart';
import '../screens/liquidation_screen.dart';
import '../leaves/leave_request_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final _pointsService = PointsService();
  final _liquidationService = LiquidationService();

  int _points = 0;
  double _dtValue = 0.0;
  int _earnedTotal = 0;
  int _deductedTotal = 0;
  String _fullName = '';
  String _firstName = '';
  List<dynamic> _recentActivity = [];
  int? _liquidationDaysLeft;
  String _liquidationName = '';
  int _leaveBalance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    PushNotificationService().initialize().catchError((_) {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.get('/auth/me'),
        _pointsService.getSummary(),
        _pointsService.getHistory('month'),
        _liquidationService.getNext().catchError((_) => <String, dynamic>{}),
      ]);

      final userData = results[0] as Map<String, dynamic>;
      final summary = results[1] as Map<String, dynamic>;
      final history = results[2] as List<dynamic>;
      final next = results[3] as Map<String, dynamic>;

      final fullName = userData['fullName'] ?? userData['full_name'] ?? 'Employé';
      final nameParts = fullName.toString().split(' ');

      if (mounted) {
        setState(() {
          _fullName = fullName;
          _firstName = nameParts.isNotEmpty ? nameParts.first : fullName;
          _points = (summary['balance'] as num?)?.toInt() ?? 0;
          _dtValue = (summary['dtValue'] as num?)?.toDouble() ?? 0.0;
          _earnedTotal = (summary['earnedTotal'] as num?)?.toInt() ?? 0;
          _deductedTotal = (summary['deductedTotal'] as num?)?.toInt() ?? 0;
          _recentActivity = history.take(3).toList();
          _liquidationDaysLeft = (next['daysRemaining'] as num?)?.toInt();
          _liquidationName = next['shortName'] as String? ?? '';
          _leaveBalance = (userData['leave_balance'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceElevated,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),

            // ── Body ───────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Balance card
                  _isLoading
                      ? const SkeletonBalance()
                      : PointsBalanceCard(
                          points: _points,
                          dtValue: _dtValue,
                          maxPoints: _earnedTotal > 0 ? _earnedTotal : 42,
                        ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: AppSpacing.m),

                  // ── Stats row ─────────────────────────────────────────
                  Row(
                    children: [
                      _StatTile(
                        label: 'Gagnés',
                        value: _isLoading ? '--' : '+$_earnedTotal',
                        icon: Icons.trending_up_rounded,
                        accentColor: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      _StatTile(
                        label: 'Perdus',
                        value: _isLoading ? '--' : '-$_deductedTotal',
                        icon: Icons.trending_down_rounded,
                        accentColor: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      _StatTile(
                        label: 'Valeur DT',
                        value: _isLoading
                            ? '--'
                            : '${_dtValue.toStringAsFixed(0)} DT',
                        icon: Icons.account_balance_wallet_outlined,
                        accentColor: AppColors.gold,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.m),

                  // ── Leave card ────────────────────────────────────────
                  if (!_isLoading)
                    _LeaveCard(
                      leaveBalance: _leaveBalance,
                      onRequest: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LeaveRequestScreen()),
                        );
                      },
                    )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 350.ms)
                        .slideY(
                            begin: 0.06,
                            end: 0,
                            delay: 150.ms,
                            duration: 350.ms),

                  if (!_isLoading) const SizedBox(height: AppSpacing.m),

                  // ── Liquidation card ──────────────────────────────────
                  if (!_isLoading && _liquidationDaysLeft != null)
                    _LiquidationCard(
                      name: _liquidationName,
                      daysLeft: _liquidationDaysLeft!,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LiquidationScreen()),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 350.ms)
                        .slideY(
                            begin: 0.08,
                            end: 0,
                            delay: 200.ms,
                            duration: 350.ms),

                  if (!_isLoading && _liquidationDaysLeft != null)
                    const SizedBox(height: AppSpacing.m),

                  // ── Activity section header ────────────────────────────
                  _SectionHeader(
                    title: 'ACTIVITÉ RÉCENTE',
                    onMore: !_isLoading ? () {} : null,
                  ),
                  const SizedBox(height: AppSpacing.s),

                  if (_isLoading) ...[
                    const SkeletonCard(),
                    const SkeletonCard(),
                    const SkeletonCard(),
                  ] else if (_recentActivity.isEmpty) ...[
                    EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Aucune transaction',
                      subtitle: 'Vos gains apparaîtront ici.',
                    ),
                  ] else
                    ..._recentActivity.asMap().entries.map(
                          (e) => TransactionItem(
                            transaction:
                                Map<String, dynamic>.from(e.value as Map),
                            index: e.key,
                          ),
                        ),

                  const SizedBox(height: AppSpacing.xxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final greeting = _timeGreeting();
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.l, topPad + AppSpacing.s, AppSpacing.l, AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top strip: LEONI logo + actions ──────────────────────────
          Row(
            children: [
              // LEONI logo
              _LeoniDashboardLogo(),
              const Spacer(),
              const NotificationBell(),
              IconButton(
                icon: const Icon(Icons.logout_outlined, size: 19),
                color: AppColors.textSecondary,
                tooltip: 'Déconnexion',
                onPressed: _logout,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // ── Greeting row ────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.brand,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'E',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              _isLoading
                  ? const SizedBox(height: 40)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          greeting,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _firstName,
                          style: AppTypography.headerSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour,';
    if (hour < 18) return 'Bon après-midi,';
    return 'Bonsoir,';
  }
}

// ── LEONI logo — image asset avec fallback branded ───────────────────────────

class _LeoniDashboardLogo extends StatelessWidget {
  const _LeoniDashboardLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/leoni_logo.png',
      height: 24,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A3875), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'LEONI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 1.8,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

// ── Stat Tile — dark with colored accent ─────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border(
            top: BorderSide(color: accentColor, width: 2.5),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: accentColor, size: 14),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              value,
              style: AppTypography.headerSmall.copyWith(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Liquidation Card ─────────────────────────────────────────────────────────

class _LiquidationCard extends StatelessWidget {
  final String name;
  final int daysLeft;
  final VoidCallback onTap;

  const _LiquidationCard({
    required this.name,
    required this.daysLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = daysLeft <= 7;
    final cardColors = isUrgent
        ? [AppColors.warning, const Color(0xFFE85D04)]
        : [AppColors.primary, AppColors.primaryDark];
    final glowColor = isUrgent ? AppColors.warning : AppColors.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l, vertical: AppSpacing.m),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: cardColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.l),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Day counter badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$daysLeft',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'jours',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liquidation $name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUrgent
                        ? 'Urgent — Vérifiez votre solde !'
                        : 'Conversion automatique de vos points',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Voir',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.chevron_right, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Leave card ───────────────────────────────────────────────────────────────

class _LeaveCard extends StatelessWidget {
  final int leaveBalance;
  final VoidCallback onRequest;

  const _LeaveCard({required this.leaveBalance, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icone congés
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.beach_access_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Congés disponibles',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$leaveBalance jour${leaveBalance > 1 ? 's' : ''}',
                  style: AppTypography.headerSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Bouton
          GestureDetector(
            onTap: onRequest,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Demander',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header with accent line ──────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;

  const _SectionHeader({required this.title, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTypography.label.copyWith(
            color: AppColors.textPrimary,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        if (onMore != null)
          GestureDetector(
            onTap: onMore,
            child: Text(
              'Voir tout',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
