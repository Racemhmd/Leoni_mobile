import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/design_system.dart';
import '../utils/constants.dart';

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

  int get _points {
    final raw = reward['pointsCost'];
    if (raw == null) return 0;
    if (raw is num) return raw.toInt();
    return double.tryParse(raw.toString())?.toInt() ?? 0;
  }
  String get _name => (reward['name'] as String?) ?? '';
  String get _description => (reward['description'] as String?) ?? '';
  String get _category => (reward['category'] as String?) ?? '';
  bool get _canAfford => userBalance >= _points;
  String get _dtValue => (_points * 10).toStringAsFixed(0);

  String? get _resolvedImageUrl {
    final url = reward['imageUrl'] as String?;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    final baseUrl = AppConstants.baseUrl.replaceAll('/api', '');
    return '$baseUrl$url';
  }

  static IconData _iconForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'voucher':
        return Icons.confirmation_num_rounded;
      case 'loisirs':
        return Icons.sports_esports_rounded;
      case 'restauration':
        return Icons.restaurant_rounded;
      case 'bien-etre':
        return Icons.spa_rounded;
      case 'electronique':
        return Icons.devices_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }

  static List<Color> _gradientForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'voucher':
        return [AppColors.primary, AppColors.primaryDark];
      case 'loisirs':
        return [const Color(0xFF7C3AED), const Color(0xFF5B21B6)];
      case 'restauration':
        return [const Color(0xFFFF6B35), const Color(0xFFE85D04)];
      case 'bien-etre':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'electronique':
        return [const Color(0xFF0EA5E9), const Color(0xFF0284C7)];
      default:
        return [const Color(0xFF6B7280), const Color(0xFF4B5563)];
    }
  }

  Widget _buildGradientIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: _canAfford
            ? LinearGradient(
                colors: _gradientForCategory(_category),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _canAfford ? null : AppColors.surfaceElevated,
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
    );
  }

  Widget _buildImageArea() {
    final url = _resolvedImageUrl;
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Container(
          color: AppColors.surfaceElevated,
          child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => _buildGradientIcon(),
      );
    }
    return _buildGradientIcon();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _canAfford ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.l),
          boxShadow: AppShadows.darkCard,
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image / icon area ─────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.l),
                      topRight: Radius.circular(AppRadius.l),
                    ),
                    child: _buildImageArea(),
                  ),
                  // Points badge overlaid top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _canAfford
                            ? AppColors.gold
                            : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: _canAfford
                            ? [
                                BoxShadow(
                                  color: AppColors.gold.withOpacity(0.5),
                                  blurRadius: 10,
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        '$_points pts',
                        style: TextStyle(
                          color: _canAfford
                              ? const Color(0xFF1A1000)
                              : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              fontSize: 13),
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
                        Text(
                          '≈ $_dtValue DT',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Redeem button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: Material(
                        color: _canAfford
                            ? AppColors.primary
                            : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(AppRadius.m),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.m),
                          onTap: _canAfford
                              ? () {
                                  HapticFeedback.lightImpact();
                                  onRedeem?.call();
                                }
                              : null,
                          child: Center(
                            child: Text(
                              _canAfford ? 'Échanger' : 'Insuffisant',
                              style: TextStyle(
                                color: _canAfford
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
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
        .slideY(
            begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}
