import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/design_system.dart';

class PointsSummaryCard extends StatelessWidget {
  final int points;
  final String role;
  final double dtValue;
  final VoidCallback? onTap;

  const PointsSummaryCard({
    super.key,
    required this.points,
    required this.role,
    this.dtValue = 0.0,
    this.onTap,
  });

  Map<String, dynamic> _getLevelInfo(int pts) {
    if (pts >= 1000) {
      return {
        'name': 'GOLD',
        'color': AppColors.gold,
        'icon': Icons.emoji_events,
        'nextLimit': 2000, 
        'minLimit': 1000,
        'gradient': AppColors.goldGradient
      };
    } else if (pts >= 500) {
      return {
        'name': 'SILVER',
        'color': AppColors.silver,
        'icon': Icons.stars,
        'nextLimit': 1000,
        'minLimit': 500,
        'gradient': AppColors.silverGradient
      };
    } else {
      return {
        'name': 'BRONZE',
        'color': AppColors.bronze,
        'icon': Icons.shield,
        'nextLimit': 500,
        'minLimit': 0,
        'gradient': AppColors.bronzeGradient
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gamified Style for Employee
    final levelInfo = _getLevelInfo(points);
    final int nextLimit = levelInfo['nextLimit'];
    final int minLimit = levelInfo['minLimit'];
    final double progress = nextLimit > 0 
        ? ((points - minLimit) / (nextLimit - minLimit)).clamp(0.0, 1.0)
        : 1.0;
    final int pointsNeeded = nextLimit - points;

    return Card(
      elevation: 4,
      shadowColor: (levelInfo['color'] as Color).withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL BALANCE', style: AppTypography.label),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$points', style: AppTypography.headerLarge.copyWith(color: AppColors.primary, fontSize: 48)),
                        const SizedBox(width: 4),
                        Text('PTS', style: AppTypography.headerSmall.copyWith(color: levelInfo['color'])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '≈ ${dtValue.toStringAsFixed(3)} DT',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: levelInfo['gradient'], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: (levelInfo['color'] as Color).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Icon(levelInfo['icon'], color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        levelInfo['name'],
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            LinearPercentIndicator(
              lineHeight: 10.0,
              percent: progress,
              barRadius: const Radius.circular(5),
              backgroundColor: Colors.grey.shade100,
              progressColor: levelInfo['color'],
              padding: EdgeInsets.zero,
              animation: true,
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    points == 0 
                        ? "Start earning points today!" 
                        : '$pointsNeeded pts to next level',
                    style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: InkWell(
                      onTap: onTap,
                      child: Row(
                        children: [
                          Text('History', style: AppTypography.label.copyWith(color: AppColors.primary)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
