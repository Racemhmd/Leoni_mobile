import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EarnSpendGuide extends StatelessWidget {
  const EarnSpendGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline, color: Colors.white),
      tooltip: 'How to Earn & Spend',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) => const _GuideModal(),
        );
      },
    );
  }
}

class _GuideModal extends StatelessWidget {
  const _GuideModal();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text(
            'How it Works',
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _Section(
                  title: 'EARN POINTS',
                  color: Colors.green,
                  icon: Icons.add_circle_outline,
                  items: const [
                    'Note: All employees start with 0 points.',
                    'Perfect Attendance: +50 pts/week',
                    'Zero Defects: +10 pts/day',
                    'Team Target Met: +100 pts/month',
                    'Shift Leader Bonus: +20 pts',
                  ],
                ),

                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Level Up! Earn badges and multiply your points by reaching Silver and Gold status.',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Got it!'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<String> items;

  const _Section({required this.title, required this.color, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 32),
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color.withOpacity(0.5), shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Text(item, style: GoogleFonts.inter(fontSize: 15, color: Colors.black87))),
            ],
          ),
        )),
      ],
    );
  }
}
