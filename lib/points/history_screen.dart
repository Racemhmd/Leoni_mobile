import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/points_service.dart';
import '../theme/design_system.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _pointsService = PointsService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String _filter = 'month'; // week, month, year

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _pointsService.getHistory(_filter);
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Points History', style: AppTypography.headerMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _filter,
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list, color: AppColors.primary),
              items: const [
                DropdownMenuItem(value: 'week', child: Text('This Week')),
                DropdownMenuItem(value: 'month', child: Text('This Month')),
                DropdownMenuItem(value: 'year', child: Text('This Year')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _filter = val);
                  _loadHistory();
                }
              },
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No transactions found', style: AppTypography.bodyMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final t = _transactions[index];
                    final isEarned = t['type'] == 'EARNED';
                    // Parse values handling different backend formats
                    final double amount = (t['value'] is int) 
                        ? (t['value'] as int).toDouble() 
                        : double.tryParse(t['value'].toString()) ?? 0.0;
                        
                    final date = DateTime.parse(t['createdAt']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.s),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isEarned ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                          child: Icon(
                            isEarned ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isEarned ? AppColors.success : AppColors.error,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          t['description'] ?? 'Transaction',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(date),
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
                        ),
                        trailing: Text(
                          '${isEarned ? '+' : '-'}${amount.toStringAsFixed(1)}',
                          style: AppTypography.headerSmall.copyWith(
                            color: isEarned ? AppColors.success : AppColors.error,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
