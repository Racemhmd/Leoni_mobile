import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecentActivityList extends StatelessWidget {
  final List<dynamic> activities; // Replacing concrete model with dynamic for flexibility here
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No recent activity',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* Header is handled in parent now mainly */
        /*
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: onViewAll, child: const Text('View All')),
          ],
        ),
        */
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length.clamp(0, 5), // Show max 5
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, index) {
              final activity = activities[index];
              final points = activity['value'] ?? 0;
              final isPositive = points > 0;
              final date = DateTime.tryParse(activity['created_at'] ?? '') ?? DateTime.now();
              final description = activity['description'] ?? activity['type'] ?? 'Unknown';

              return ListTile(
                dense: true,
                leading: Icon(
                  isPositive ? Icons.check_circle : Icons.remove_circle,
                  color: isPositive ? const Color(0xFF28A745) : const Color(0xFFDC3545),
                  size: 20,
                ),
                title: Text(
                  description,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                subtitle: Text(
                  DateFormat('MMM d, y HH:mm').format(date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                trailing: Text(
                  '${isPositive ? '+' : ''}$points',
                  style: TextStyle(
                    color: isPositive ? const Color(0xFF28A745) : const Color(0xFFDC3545),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onTap: () {}, // No-op or navigate
              );
            },
          ),
        ),
      ],
    );
  }
}
