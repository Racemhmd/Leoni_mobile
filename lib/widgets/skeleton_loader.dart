import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/design_system.dart';

// A single shimmering rectangle — building block for all skeletons.
class _ShimBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _ShimBox({
    this.width,
    required this.height,
    this.radius = AppRadius.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: const Color(0xFFF9FAFB));
  }
}

/// Skeleton for a single TransactionItem row.
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 5),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.m),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          _ShimBox(width: 42, height: 42, radius: AppRadius.s),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ShimBox(height: 13, width: double.infinity),
                const SizedBox(height: 6),
                const _ShimBox(height: 10, width: 120),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              _ShimBox(height: 16, width: 56),
              SizedBox(height: 4),
              _ShimBox(height: 10, width: 36),
            ],
          ),
        ],
      ),
    );
  }
}

/// A column of [count] skeleton cards.
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const SkeletonCard()),
    );
  }
}

/// Skeleton that mimics the PointsBalanceCard.
class SkeletonBalance extends StatelessWidget {
  const SkeletonBalance({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: const Color(0xFFF3F4F6));
  }
}

/// Skeleton for a grid reward card.
class SkeletonGridCard extends StatelessWidget {
  const SkeletonGridCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE5E7EB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.l),
                  topRight: Radius.circular(AppRadius.l),
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: const Color(0xFFF3F4F6)),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _ShimBox(height: 13, width: double.infinity),
                  _ShimBox(height: 10, width: 80),
                  _ShimBox(height: 28, width: double.infinity),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
