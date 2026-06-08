import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/points_service.dart';
import '../theme/design_system.dart';
import '../widgets/transaction_item.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _pointsService = PointsService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String _filter = 'month';

  static const _filters = [
    ('week', 'Semaine'),
    ('month', 'Mois'),
    ('year', 'Année'),
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _pointsService.getHistory(_filter);
      if (mounted) setState(() => _transactions = data);
    } catch (e) {
      debugPrint('History load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setFilter(String filter) {
    if (filter == _filter) return;
    HapticFeedback.selectionClick();
    setState(() => _filter = filter);
    _loadHistory();
  }

  // Group transactions by month label
  Map<String, List<dynamic>> _groupByMonth(List<dynamic> txns) {
    final grouped = <String, List<dynamic>>{};
    for (final t in txns) {
      try {
        final date = DateTime.parse(t['createdAt'] as String);
        final key = DateFormat('MMMM yyyy', 'fr_FR').format(date);
        grouped.putIfAbsent(key, () => []).add(t);
      } catch (_) {
        grouped.putIfAbsent('Autres', () => []).add(t);
      }
    }
    return grouped;
  }

  int get _totalEarned => _transactions
      .where((t) => t['type'] == 'EARNED')
      .fold(0, (sum, t) => sum + ((t['value'] as num?)?.toInt() ?? 0));

  int get _totalDeducted => _transactions
      .where((t) => t['type'] != 'EARNED')
      .fold(0, (sum, t) => sum + ((t['value'] as num?)?.toInt() ?? 0));

  @override
  Widget build(BuildContext context) {
    final grouped = _isLoading ? <String, List<dynamic>>{} : _groupByMonth(_transactions);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.l, AppSpacing.m, AppSpacing.l, 0),
                    child: Text('Transactions',
                        style: AppTypography.headerLarge
                            .copyWith(color: Colors.white)),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  // Filter pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
                    child: Row(
                      children: _filters.map((f) {
                        final active = _filter == f.$1;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.s),
                          child: GestureDetector(
                            onTap: () => _setFilter(f.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.l, vertical: AppSpacing.s),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                                border: Border.all(
                                  color: active
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                f.$2,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? AppColors.primary
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const SkeletonList(count: 6)
                : _transactions.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Aucune transaction',
                        subtitle:
                            'Aucun mouvement de points sur cette période.',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                              top: AppSpacing.m, bottom: AppSpacing.xxl),
                          itemCount: _buildItemList(grouped).length,
                          itemBuilder: (ctx, i) {
                            return _buildItemList(grouped)[i];
                          },
                        ),
                      ),
          ),

          // ── Summary bar ──────────────────────────────────────────────────
          if (!_isLoading && _transactions.isNotEmpty)
            _SummaryBar(earned: _totalEarned, deducted: _totalDeducted),
        ],
      ),
    );
  }

  List<Widget> _buildItemList(Map<String, List<dynamic>> grouped) {
    final items = <Widget>[];
    var globalIndex = 0;
    for (final entry in grouped.entries) {
      items.add(_SectionHeader(label: entry.key));
      for (final t in entry.value) {
        items.add(TransactionItem(
            transaction: Map<String, dynamic>.from(t as Map),
            index: globalIndex++));
      }
    }
    return items;
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.s),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Summary Bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final int earned;
  final int deducted;
  const _SummaryBar({required this.earned, required this.deducted});

  @override
  Widget build(BuildContext context) {
    final net = earned - deducted;
    final netPositive = net >= 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.bottomNav,
        border: const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l, vertical: AppSpacing.m),
          child: Row(
            children: [
              _StatChip(
                label: 'Gagné',
                value: '+$earned pts',
                color: AppColors.success,
                bg: AppColors.successLight,
              ),
              const SizedBox(width: AppSpacing.s),
              _StatChip(
                label: 'Déduit',
                value: '-$deducted pts',
                color: AppColors.error,
                bg: AppColors.errorLight,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: netPositive
                      ? AppColors.successLight
                      : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${netPositive ? '+' : ''}$net pts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: netPositive ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          Text(
            value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
