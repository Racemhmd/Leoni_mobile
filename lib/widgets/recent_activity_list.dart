import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import 'package:intl/intl.dart';

class RecentActivityList extends StatelessWidget {
  final List<dynamic> activities;
  final VoidCallback onViewAll;

  const RecentActivityList({
    super.key,
    required this.activities,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
               Icon(Icons.history, size: 48, color: Colors.grey.shade300),
               const SizedBox(height: 8),
               Text('No recent activity', style: AppTypography.bodySmall.copyWith(color: AppColors.textLight)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.take(5).length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final activity = activities[index];
        final isCredit = (activity['points'] ?? 0) > 0;
        final date = DateTime.tryParse(activity['createdAt'].toString()) ?? DateTime.now();
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: isCredit ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? AppColors.success : AppColors.error,
                size: 20,
              ),
            ),
            title: Text(
              activity['description'] ?? 'Transaction',
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              DateFormat('MMM d, h:mm a').format(date),
              style: AppTypography.label.copyWith(color: AppColors.textLight),
            ),
            trailing: Text(
              '${isCredit ? '+' : ''}${activity['points']}',
              style: AppTypography.headerSmall.copyWith(
                color: isCredit ? AppColors.success : AppColors.error,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
