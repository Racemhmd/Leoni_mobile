import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/design_system.dart';
import '../widgets/reward_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import '../widgets/confirm_modal.dart';

class XmallScreen extends StatefulWidget {
  const XmallScreen({super.key});

  @override
  State<XmallScreen> createState() => _XmallScreenState();
}

class _XmallScreenState extends State<XmallScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();

  static const double _pointToDtRate = 10.0;

  int _balance = 0;
  List<Map<String, dynamic>>? _rewards;
  bool _isLoadingBalance = false;
  bool _isLoadingRewards = false;
  bool _isRedeeming = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _searchController.addListener(
        () => setState(() => _searchQuery = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchBalance(), _fetchRewards()]);
  }

  Future<void> _fetchBalance() async {
    setState(() => _isLoadingBalance = true);
    try {
      final res = await _apiService.get('/points/balance');
      if (mounted) {
        setState(() => _balance = (res['points'] as num?)?.toInt() ?? 0);
      }
    } catch (e) {
      debugPrint('Balance error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _fetchRewards() async {
    setState(() => _isLoadingRewards = true);
    try {
      final res = await _apiService.get('/points/rewards');
      if (mounted && res is List) {
        setState(() {
          _rewards =
              res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (e) {
      debugPrint('Rewards error: $e');
      if (mounted) setState(() => _rewards = []);
    } finally {
      if (mounted) setState(() => _isLoadingRewards = false);
    }
  }

  Future<void> _redeem(Map<String, dynamic> item) async {
    final itemPoints = (item['points'] as num).toInt();
    if (_balance < itemPoints) {
      _showSnack('Solde insuffisant !', isError: true);
      return;
    }

    final afterBalance = _balance - itemPoints;
    final confirmed = await ConfirmModal.show(
      context,
      title: 'Confirmer l\'échange',
      description: 'Vous êtes sur le point d\'échanger "${item['name']}".',
      confirmLabel: 'Échanger',
      extra: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BalanceLine(
              label: 'Avant',
              pts: _balance,
              color: AppColors.textPrimary,
            ),
            const Icon(Icons.arrow_forward,
                size: 16, color: AppColors.textSecondary),
            _BalanceLine(
              label: 'Après',
              pts: afterBalance,
              color:
                  afterBalance < 0 ? AppColors.error : AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRedeeming = true);
    HapticFeedback.mediumImpact();
    try {
      await _apiService.post('/points/xmall', {
        'points': itemPoints,
        'description': 'Échange XMALL : ${item['name']}',
      });
      _showSnack('Échange réussi ! Profitez de votre récompense.');
      _fetchBalance();
    } catch (e) {
      _showSnack('Échec de la transaction', isError: true);
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredRewards {
    if (_rewards == null) return [];
    if (_searchQuery.isEmpty) return _rewards!;
    final q = _searchQuery.toLowerCase();
    return _rewards!
        .where((r) =>
            (r['name'] as String? ?? '').toLowerCase().contains(q) ||
            (r['description'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRewards;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Header ───────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 150,
                backgroundColor: AppColors.primaryDark,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.l,
                      MediaQuery.of(context).padding.top + AppSpacing.m,
                      AppSpacing.l,
                      AppSpacing.m,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Récompenses',
                            style: AppTypography.headerLarge
                                .copyWith(color: Colors.white)),
                        const SizedBox(height: AppSpacing.s),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.m, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.stars_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  _isLoadingBalance
                                      ? const SizedBox(
                                          width: 40,
                                          height: 14,
                                          child: LinearProgressIndicator(
                                              color: Colors.white70),
                                        )
                                      : Text(
                                          '$_balance pts',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Text(
                              '= ${(_balance * _pointToDtRate).toStringAsFixed(0)} DT',
                              style: AppTypography.bodySmall
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une récompense…',
                        prefixIcon:
                            const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 0),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Grid ─────────────────────────────────────────────────────
              if (_isLoadingRewards)
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: AppSpacing.m,
                      mainAxisSpacing: AppSpacing.m,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const SkeletonGridCard(),
                      childCount: 6,
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.card_giftcard_outlined,
                    title: _searchQuery.isNotEmpty
                        ? 'Aucun résultat'
                        : 'Aucune récompense',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'Essayez un autre mot-clé.'
                        : 'Le catalogue est vide pour l\'instant.',
                    actionLabel:
                        _searchQuery.isEmpty ? 'Réessayer' : null,
                    onAction: _searchQuery.isEmpty ? _fetchRewards : null,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.xxl),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: AppSpacing.m,
                      mainAxisSpacing: AppSpacing.m,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => RewardCard(
                        reward: filtered[i],
                        userBalance: _balance,
                        index: i,
                        onRedeem: () => _redeem(filtered[i]),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),

          // ── Redeeming overlay ────────────────────────────────────────────
          if (_isRedeeming)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// ── Balance line for confirm modal ────────────────────────────────────────────

class _BalanceLine extends StatelessWidget {
  final String label;
  final int pts;
  final Color color;

  const _BalanceLine({
    required this.label,
    required this.pts,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(
          '$pts pts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
