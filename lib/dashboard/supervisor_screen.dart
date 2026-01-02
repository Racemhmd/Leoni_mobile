import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../auth/login_screen.dart';

class SupervisorScreen extends StatefulWidget {
  const SupervisorScreen({super.key});

  @override
  State<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<SupervisorScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;

  // Mock data for now, replace with actual API calls later
  final int _pendingApprovals = 3;
  final int _teamPresent = 12;
  final int _teamAbsent = 2;

  void _handleLogout() async {
    await _apiService.logout();
    if (mounted) {
       Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'TEAM SUPERVISION',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCards(),
                const SizedBox(height: 24),
                const Text(
                  'QUICK ACTIONS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.0),
                ),
                const SizedBox(height: 12),
                _buildActionButtons(),
                const SizedBox(height: 24),
                Text(
                  'Pending Approvals',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildPendingList()),
              ],
            ),
          ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Present',
            value: '$_teamPresent',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Absent',
            value: '$_teamAbsent',
            icon: Icons.cancel_outlined,
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Team Roster...')));
            },
            icon: const Icon(Icons.people),
            label: const Text('Team Roster'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: const Color(0xFF1A1A2E),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Reports...')));
            },
            icon: const Icon(Icons.bar_chart),
            label: const Text('Reports'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: const Color(0xFF1A1A2E),
              side: const BorderSide(color: Color(0xFF1A1A2E)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingList() {
    if (_pendingApprovals == 0) {
      return Center(
        child: Text('No pending approvals', style: GoogleFonts.inter(color: Colors.grey)),
      );
    }
    
    // Mock list
    return ListView.builder(
      itemCount: _pendingApprovals,
      itemBuilder: (ctx, i) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.access_time, color: Colors.white)),
            title: Text('Leave Request #${100 + i}'),
            subtitle: const Text('John Doe • Sick Leave'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View Request Details')));
            },
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
