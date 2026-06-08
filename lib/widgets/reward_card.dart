import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/design_system.dart';

class RewardCard extends StatelessWidget {
  final Map<String, dynamic> reward;
  final int userBalance;
  final int index;
  final VoidCallback? onRedeem;

  const RewardCard({
    super.key,
    required this.reward,
    required this.userBalance,
    this.index = 0,
    this.onRedeem,
  });

  int get _points => (reward['points'] as num?)?.toInt() ?? 0;
  String get _name => (reward['name'] as String?) ?? '';
  String get _description => (reward['description'] as String?) ?? '';
  String get _category => (reward['category'] as String?) ?? '';
  bool get _canAfford => userBalance >= _points;
  String get _dtValue => (_points * 10).toStringAsFixed(0);

  static IconData _iconForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'voucher': return Icons.confirmation_num_rounded;
      case 'loisirs': return Icons.sports_esports_rounded;
      case 'restauration': return Icons.restaurant_rounded;
      case 'bien-etre': return Icons.spa_rounded;
      case 'electronique': return Icons.devices_rounded;
      default: return Icons.card_giftcard_rounded;
    }
  }

  static List<Color> _gradientForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'voucher': return [Color(0xFF1A56DB), Color(0xFF1E3A8A)];
      case 'loisirs': return [Color(0xFF7C3AED), Color(0xFF5B21B6)];
      case 'restauration': return [Color(0xFFFF6B35), Color(0xFFE85D04)];
      case 'bien-etre': return [Color(0xFF10B981), Color(0xFF059669)];
      case 'electronique': return [Color(0xFF0EA5E9), Color(0xFF0284C7)];
      default: return [Color(0xFF6B7280), Color(0xFF4B5563)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _canAfford ? 1.0 : 0.55,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.l),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image / icon area ─────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _canAfford
                      ? LinearGradient(
                          colors: _gradientForCategory(_category),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _canAfford ? null : AppColors.surfaceElevated,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.l),
                    topRight: Radius.circular(AppRadius.l),
                  ),
                ),
                child: Center(
                  child: Icon(
                    _iconForCategory(_category),
                    size: 38,
                    color: _canAfford
                        ? Colors.white.withOpacity(0.9)
                        : AppColors.textSecondary.withOpacity(0.35),
                  ),
                ),
              ),
            ),
            // ── Content ───────────────────────────────────────────────────
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name + description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700, height: 1.25),
                        ),
                        if (_description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption,
                          ),
                        ],
                        const SizedBox(height: 4),
                        // DT value
                        Text(
                          '= $_dtValue DT',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Points badge + action button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: _canAfford
                                ? LinearGradient(
                                    colors: _gradientForCategory(_category),
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: _canAfford ? null : AppColors.surfaceElevated,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            '$_points pts',
                            style: TextStyle(
                              color: _canAfford
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Exchange button
                        Material(
                          color: _canAfford
                              ? AppColors.primary
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _canAfford
                                ? () {
                                    HapticFeedback.lightImpact();
                                    onRedeem?.call();
                                  }
                                : null,
                            child: const SizedBox(
                              width: 30,
                              height: 30,
                              child: Icon(Icons.arrow_forward_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}
