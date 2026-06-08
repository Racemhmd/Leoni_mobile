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
    final greeting = _timeGreeting();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── SliverAppBar ───────────────────────────────────────────────
            SliverAppBar(
              pinned: false,
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              expandedHeight: 0,
              titleSpacing: AppSpacing.l,
              title: _isLoading
                  ? null
                  : Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A56DB), Color(0xFF1E3A8A)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _firstName.isNotEmpty
                                  ? _firstName[0].toUpperCase()
                                  : 'E',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                greeting,
                                style: AppTypography.caption,
                              ),
                              Text(
                                _firstName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              actions: [
                const NotificationBell(),
                IconButton(
                  icon: const Icon(Icons.logout_outlined, size: 20),
                  color: AppColors.textSecondary,
                  tooltip: 'Déconnexion',
                  onPressed: _logout,
                ),
                const SizedBox(width: AppSpacing.s),
              ],
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

                  const SizedBox(height: AppSpacing.l),

                  // ── Quick actions ────────────────────────────────────────
                  Row(
                    children: [
                      _QuickAction(
                        label: 'Gagnés',
                        value: _isLoading ? '--' : '+$_earnedTotal',
                        icon: Icons.trending_up_rounded,
                        bg: const Color(0xFFD1FAE5),
                        fg: const Color(0xFF065F46),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      _QuickAction(
                        label: 'Perdus',
                        value: _isLoading ? '--' : '-$_deductedTotal',
                        icon: Icons.trending_down_rounded,
                        bg: const Color(0xFFFEE2E2),
                        fg: const Color(0xFF991B1B),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      _QuickAction(
                        label: 'Solde DT',
                        value: _isLoading ? '--' : '${_dtValue.toStringAsFixed(0)} DT',
                        icon: Icons.account_balance_wallet_outlined,
                        bg: const Color(0xFFEDE9FE),
                        fg: const Color(0xFF5B21B6),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.l),

                  // ── Liquidation card ────────────────────────────────────
                  if (!_isLoading && _liquidationDaysLeft != null)
                    _LiquidationCard(
                      name: _liquidationName,
                      daysLeft: _liquidationDaysLeft!,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LiquidationScreen()),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                  if (!_isLoading && _liquidationDaysLeft != null)
                    const SizedBox(height: AppSpacing.l),

                  // ── Recent activity ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Activité récente', style: AppTypography.headerSmall),
                      if (!_isLoading)
                        TextButton(
                          onPressed: () {},
                          child: const Text('Voir tout'),
                        ),
                    ],
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

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour,';
    if (hour < 18) return 'Bon après-midi,';
    return 'Bonsoir,';
  }
}

// ── Quick Action tile ────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bg;
  final Color fg;

  const _QuickAction({
    required this.label,
    required this.value,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.m),
          boxShadow: AppShadows.soft,
          border: Border(
            top: BorderSide(color: fg.withOpacity(0.45), width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: fg, size: 16),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              value,
              style: AppTypography.headerSmall.copyWith(fontSize: 15),
            ),
            Text(label, style: AppTypography.caption),
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
        ? [const Color(0xFFFF6B35), const Color(0xFFFF9A5C)]
        : [const Color(0xFF1A56DB), const Color(0xFF1E3A8A)];

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
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 20,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    isUrgent
                        ? 'Dans $daysLeft j. — Vérifiez votre solde !'
                        : 'Dans $daysLeft jours',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
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
