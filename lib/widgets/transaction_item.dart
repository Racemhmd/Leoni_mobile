import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/design_system.dart';

class TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final int index;

  const TransactionItem({super.key, required this.transaction, this.index = 0});

  bool get _isEarned => transaction['type'] == 'EARNED';

  double get _amount {
    final v = transaction['value'];
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String get _description {
    final raw = (transaction['description'] ?? transaction['reason'] ?? '') as String;
    if (raw.isEmpty) return 'Transaction';
    return raw;
  }

  DateTime get _date {
    try {
      return DateTime.parse(transaction['createdAt'] as String);
    } catch (_) {
      return DateTime.now();
    }
  }

  static IconData _iconFor(String reason) {
    final r = reason.toUpperCase();
    if (r.contains('BEST_EMPLOYEE')) return Icons.emoji_events_rounded;
    if (r.contains('BEST_TEAM')) return Icons.groups_rounded;
    if (r.contains('AIP')) return Icons.star_rounded;
    if (r.contains('CIP')) return Icons.check_circle_rounded;
    if (r.contains('PRESENCE')) return Icons.calendar_today_rounded;
    if (r.contains('PLANT')) return Icons.factory_rounded;
    if (r.contains('ABSENCE')) return Icons.event_busy_rounded;
    if (r.contains('DELAY')) return Icons.schedule_rounded;
    if (r.contains('DISCIPLIN')) return Icons.gavel_rounded;
    if (r.contains('REWARD') || r.contains('XMALL')) return Icons.card_giftcard_rounded;
    return Icons.swap_horiz_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _isEarned ? AppColors.success : AppColors.error;
    final bgColor = _isEarned ? AppColors.successLight : AppColors.errorLight;
    final sign = _isEarned ? '+' : '−';
    final dtValue = (_amount * 10).toStringAsFixed(0);
    final reason = (transaction['reason'] ?? '') as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.m),
        boxShadow: AppShadows.soft,
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.s),
            ),
            child: Icon(_iconFor(reason), color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Description + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _description,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM yyyy').format(_date),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          // Points + DT
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${_amount.toStringAsFixed(1)} pts',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$sign$dtValue DT',
                style: AppTypography.caption
                    .copyWith(color: color.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 45 * index))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.12, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}
