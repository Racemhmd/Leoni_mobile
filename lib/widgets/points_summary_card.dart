import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PointsSummaryCard extends StatelessWidget {
  final int points;
  final String role; // Kept for generic usage, but Level takes precedence
  final VoidCallback? onTap;

  const PointsSummaryCard({
    super.key,
    required this.points,
    required this.role,
    this.onTap,
  });

  Map<String, dynamic> _getLevelInfo(int pts) {
    if (pts >= 1000) {
      return {
        'name': 'GOLD',
        'color': const Color(0xFFFFD700),
        'icon': Icons.emoji_events,
        'nextLimit': 2000, 
        'minLimit': 1000,
        'gradient': [const Color(0xFFFDB931), const Color(0xFFFFD700), const Color(0xFFFDB931)]
      };
    } else if (pts >= 500) {
      return {
        'name': 'SILVER',
        'color': const Color(0xFFC0C0C0),
        'icon': Icons.stars,
        'nextLimit': 1000,
        'minLimit': 500,
        'gradient': [const Color(0xFFE0E0E0), const Color(0xFFBDBDBD)]
      };
    } else {
      return {
        'name': 'BRONZE',
        'color': const Color(0xFFCD7F32),
        'icon': Icons.shield,
        'nextLimit': 500,
        'minLimit': 0,
        'gradient': [const Color(0xFFCD7F32), const Color(0xFFA0522D)]
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enterprise style: Clean, clear, no gradients, minimal color
    final levelInfo = _getLevelInfo(points);
    final int nextLimit = levelInfo['nextLimit'];
    final int minLimit = levelInfo['minLimit'];
    final double progress = nextLimit > 0 
        ? ((points - minLimit) / (nextLimit - minLimit)).clamp(0.0, 1.0)
        : 1.0;
    final int pointsNeeded = nextLimit - points;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL BALANCE', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$points', style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: const Color(0xFF003366))),
                        const SizedBox(width: 4),
                        Text('PTS', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFFDB931))),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: levelInfo['gradient'], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: (levelInfo['color'] as Color).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Icon(levelInfo['icon'], color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        levelInfo['name'],
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent: progress,
              barRadius: const Radius.circular(4),
              backgroundColor: Colors.grey.shade200,
              progressColor: levelInfo['color'],
              padding: EdgeInsets.zero,
              animation: true,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    points == 0 
                        ? "You haven't earned points yet.\nStart by participating and engaging!" 
                        : '$pointsNeeded pts to next level',
                    style: GoogleFonts.poppins(
                      color: points == 0 ? Colors.grey.shade600 : Colors.grey.shade600, 
                      fontSize: 12, 
                      fontStyle: FontStyle.italic
                    ),
                  ),
                ),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: InkWell(
                      onTap: onTap,
                      child: Row(
                        children: [
                          Text('History', style: GoogleFonts.poppins(color: const Color(0xFF003366), fontWeight: FontWeight.w600, fontSize: 12)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF003366)),
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
