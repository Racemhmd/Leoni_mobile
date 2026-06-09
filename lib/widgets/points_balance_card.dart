import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/design_system.dart';

class PointsBalanceCard extends StatelessWidget {
  final int points;
  final double dtValue;
  final int maxPoints;

  const PointsBalanceCard({
    super.key,
    required this.points,
    required this.dtValue,
    this.maxPoints = 42,
  });

  String get _level {
    if (points >= 100) return 'OR';
    if (points >= 50) return 'ARGENT';
    if (points >= 20) return 'BRONZE';
    return 'DÉBUTANT';
  }

  Color get _levelColor {
    if (points >= 100) return AppColors.gold;
    if (points >= 50) return AppColors.silver;
    if (points >= 20) return AppColors.bronze;
    return AppColors.textSecondary;
  }

  List<Color> get _ringColors {
    if (points >= 100) return [AppColors.goldLight, AppColors.gold, AppColors.goldDark];
    if (points >= 50) return [const Color(0xFFE2E8F0), AppColors.silver];
    if (points >= 20) return [const Color(0xFFE4A96C), AppColors.bronze];
    return [AppColors.textSecondary, AppColors.textMuted];
  }

  @override
  Widget build(BuildContext context) {
    final progress = (points / maxPoints).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      height: 218,
      decoration: BoxDecoration(
        gradient: AppGradients.dark,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.darkCard,
        border: Border.all(color: AppColors.surfaceDarkBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            // ── Grid texture ─────────────────────────────────────────────────
            Positioned.fill(child: CustomPaint(painter: _CardGridPainter())),

            // ── Gold glow (right side, behind the ring) ───────────────────────
            Positioned(
              right: -10,
              bottom: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _levelColor.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Top cyan accent line ─────────────────────────────────────────
            Positioned(
              top: 0,
              left: 24,
              right: 130,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0),
                  ]),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 18),
              child: Row(
                children: [
                  // Left info panel
                  Expanded(
                    flex: 55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOLDE DE POINTS',
                          style: AppTypography.labelBright
                              .copyWith(fontSize: 9, letterSpacing: 1.8),
                        ),
                        const SizedBox(height: 9),
                        _LevelBadge(label: _level, color: _levelColor),
                        const Spacer(),
                        // DT badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.toll_rounded,
                                  size: 11, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '≈ ${dtValue.toStringAsFixed(0)} DT',
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Progress label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PROGRESSION',
                              style: AppTypography.labelBright.copyWith(
                                  fontSize: 8, letterSpacing: 1.0),
                            ),
                            Text(
                              '$points / $maxPoints',
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Progress bar (gold)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: AppDurations.progress,
                            curve: Curves.easeOutCubic,
                            builder: (_, val, __) => Stack(
                              children: [
                                Container(
                                  height: 4,
                                  width: double.infinity,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                                FractionallySizedBox(
                                  widthFactor: val,
                                  child: Container(
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      gradient: AppGradients.goldSheen,
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

                  const SizedBox(width: 6),

                  // Right ring
                  _PointsRing(
                    points: points,
                    progress: progress,
                    ringColors: _ringColors,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0, duration: 400.ms);
  }
}

// ── Level badge ───────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _LevelBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech_rounded, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Points ring ───────────────────────────────────────────────────────────────

class _PointsRing extends StatelessWidget {
  final int points;
  final double progress;
  final List<Color> ringColors;

  const _PointsRing({
    required this.points,
    required this.progress,
    required this.ringColors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: AppDurations.progress,
        curve: Curves.easeOutCubic,
        builder: (_, animProgress, __) {
          return CustomPaint(
            painter: _RingPainter(
              progress: animProgress,
              trackColor: const Color(0xFF1A2845),
              ringColors: ringColors,
              strokeWidth: 9,
            ),
            child: Center(
              child: TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: points),
                duration: AppDurations.counter,
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatPoints(v),
                      style: GoogleFonts.syne(
                        fontSize: points >= 1000 ? 26 : 32,
                        fontWeight: FontWeight.w800,
                        color: ringColors.last == AppColors.textMuted
                            ? AppColors.textPrimary
                            : ringColors[ringColors.length ~/ 2],
                        height: 1.0,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'pts',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _formatPoints(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return '$v';
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final List<Color> ringColors;
  final double strokeWidth;

  static const double _startAngle = 135.0 * math.pi / 180.0;
  static const double _totalSweep = 270.0 * math.pi / 180.0;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.ringColors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track arc
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    canvas.drawArc(rect, _startAngle, _totalSweep, false, trackPaint);

    if (progress <= 0) return;

    final sweepAngle = _totalSweep * progress;

    // Progress arc with gradient
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: ringColors,
        startAngle: _startAngle,
        endAngle: _startAngle + _totalSweep,
        tileMode: TileMode.clamp,
      ).createShader(rect);

    canvas.drawArc(rect, _startAngle, sweepAngle, false, progressPaint);

    // Cap glow dot at the progress tip
    if (progress > 0.05) {
      final tipAngle = _startAngle + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);

      canvas.drawCircle(
        Offset(tipX, tipY),
        strokeWidth / 2,
        Paint()..color = ringColors.last.withOpacity(0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.ringColors != ringColors;
}

// ── Card grid texture ─────────────────────────────────────────────────────────

class _CardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF06B6D4).withOpacity(0.04)
      ..strokeWidth = 0.5;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardGridPainter old) => false;
}
