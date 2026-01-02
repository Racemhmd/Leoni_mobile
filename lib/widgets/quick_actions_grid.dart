import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class QuickActionsGrid extends StatelessWidget {
  final List<QuickActionItem> actions;

  const QuickActionsGrid({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Simple responsiveness
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _ActionCard(action: action, index: index);
          },
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final QuickActionItem action;
  final int index;

  const _ActionCard({required this.action, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (action.color ?? const Color(0xFF003366)).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action.icon,
                    size: 24,
                    color: action.color ?? const Color(0xFF003366),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13, 
                    fontWeight: FontWeight.w600, 
                    color: Colors.grey.shade800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
