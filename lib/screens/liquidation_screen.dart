import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/liquidation_service.dart';
import '../theme/design_system.dart';

class LiquidationScreen extends StatefulWidget {
  const LiquidationScreen({super.key});

  @override
  State<LiquidationScreen> createState() => _LiquidationScreenState();
}

class _LiquidationScreenState extends State<LiquidationScreen> {
  final _service = LiquidationService();

  bool _isLoading = true;
  Map<String, dynamic>? _next;
  List<dynamic>? _calendar;
  Map<String, dynamic>? _preview;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getNext(),
        _service.getCalendar(),
        _service.getMyPreview(),
      ]);
      if (mounted) {
        setState(() {
          _next    = results[0] as Map<String, dynamic>;
          _calendar = results[1] as List<dynamic>;
          _preview = results[2] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Liquidations',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNextSession(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionLabel('CALENDRIER ANNUEL'),
                        const SizedBox(height: AppSpacing.m),
                        _buildCalendar(),
                        if (_preview != null) ...[
                          const SizedBox(height: AppSpacing.xl),
                          _buildSectionLabel('MES POINTS DE CETTE PÉRIODE'),
                          const SizedBox(height: AppSpacing.m),
                          _buildPeriodDetails(),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ── Section 1 : Prochaine liquidation ──────────────────────────────────────

  Widget _buildNextSession() {
    if (_next == null) return const SizedBox.shrink();
    final days = (_next!['daysRemaining'] as num?)?.toInt() ?? 0;
    final name = _next!['name'] as String? ?? '';
    final dateStr = _next!['executionDate'] as String? ?? '';
    final preview = _preview?['preview'] as Map<String, dynamic>?;
    final estimatedDT = (preview?['amountDT'] as num?)?.toDouble() ?? 0;
    final totalDays = 91; // ~1 trimestre
    final progress = (1 - days / totalDays).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003D89), Color(0xFF005FCC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.event_repeat, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text('PROCHAINE LIQUIDATION', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(dateStr, style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 20),

          // Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _countdownChip(days, 'jours restants'),
              if (estimatedDT > 0)
                _dtChip(estimatedDT),
            ],
          ),
          const SizedBox(height: 16),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Début période', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
              Text('$days j.', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
              Text('Liquidation', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _countdownChip(int days, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$days', style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _dtChip(double dt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('${dt.toStringAsFixed(0)} DT',
              style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
          Text('estimé', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  // ── Section 2 : Calendrier annuel ─────────────────────────────────────────

  Widget _buildCalendar() {
    if (_calendar == null || _calendar!.isEmpty) {
      return const Text('Calendrier non disponible', style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: List.generate(_calendar!.length, (i) {
        final session = _calendar![i] as Map<String, dynamic>;
        return _buildSessionCard(session, i);
      }),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session, int index) {
    final status = session['status'] as String? ?? 'UPCOMING';
    final name = session['name'] as String? ?? '';
    final date = session['executionDate'] as String? ?? '';
    final daysLeft = session['daysRemaining'] as int?;
    final totalDT = (session['totalAmountDT'] as num?)?.toDouble();
    final totalEmp = session['totalEmployees'] as int?;

    final (Color color, IconData icon, String statusLabel) = switch (status) {
      'COMPLETED' => (AppColors.success, Icons.check_circle, 'Effectuée'),
      'CURRENT'   => (AppColors.warning, Icons.pending, 'En cours'),
      'MISSED'    => (AppColors.error,   Icons.error_outline, 'Manquée'),
      _           => (AppColors.info,    Icons.calendar_today, 'À venir'),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: status == 'CURRENT' ? 4 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ),
        trailing: status == 'COMPLETED' && totalDT != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${totalDT.toStringAsFixed(0)} DT',
                      style: GoogleFonts.outfit(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)),
                  if (totalEmp != null)
                    Text('$totalEmp employés', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
                ],
              )
            : daysLeft != null
                ? Text('$daysLeft j.', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13))
                : null,
        isThreeLine: true,
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 80 * index)).slideX(begin: 0.05, end: 0);
  }

  // ── Section 3 : Points de la période ──────────────────────────────────────

  Widget _buildPeriodDetails() {
    final preview = _preview?['preview'] as Map<String, dynamic>?;
    if (preview == null) return const SizedBox.shrink();

    final earned = (preview['earnedEvents'] as List<dynamic>?) ?? [];
    final deducted = (preview['deductedEvents'] as List<dynamic>?) ?? [];
    final netPoints = (preview['netPoints'] as num?)?.toDouble() ?? 0;
    final amountDT = (preview['amountDT'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Résumé net
        _buildNetSummary(netPoints, amountDT),
        const SizedBox(height: AppSpacing.m),

        // Événements positifs
        if (earned.isNotEmpty) ...[
          _buildEventGroup('Points gagnés', earned, isGain: true),
          const SizedBox(height: AppSpacing.m),
        ] else
          _buildEmptyState('Aucun gain enregistré pour cette période', Icons.star_outline),

        // Événements négatifs
        if (deducted.isNotEmpty)
          _buildEventGroup('Points déduits', deducted, isGain: false)
        else
          _buildEmptyState('Aucune déduction pour cette période', Icons.shield_outlined),
      ],
    );
  }

  Widget _buildNetSummary(double netPoints, double amountDT) {
    return Container(
      decoration: BoxDecoration(
        color: netPoints > 0 ? AppColors.success.withOpacity(0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: netPoints > 0 ? AppColors.success.withOpacity(0.3) : Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(netPoints > 0 ? Icons.trending_up : Icons.trending_flat,
              color: netPoints > 0 ? AppColors.success : Colors.grey, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Solde net estimé',
                    style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12)),
                Text('${netPoints.toStringAsFixed(1)} pts',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 20,
                        color: netPoints > 0 ? AppColors.success : AppColors.textDark)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Valeur estimée', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
              Text('${amountDT.toStringAsFixed(0)} DT',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 18,
                      color: netPoints > 0 ? AppColors.success : AppColors.textDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventGroup(String title, List<dynamic> events, {required bool isGain}) {
    final color = isGain ? AppColors.success : AppColors.error;
    final sign  = isGain ? '+' : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(isGain ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 14),
          const SizedBox(width: 6),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
        ]),
        const SizedBox(height: 8),
        ...events.map((e) {
          final event = e as Map<String, dynamic>;
          final reason = (event['reason'] as String? ?? '').replaceAll('_', ' ');
          final value  = (event['value'] as num?)?.toDouble() ?? 0;
          final date   = event['date'] as String? ?? '';
          return _buildEventTile(reason, value, date, isGain: isGain);
        }),
      ],
    );
  }

  Widget _buildEventTile(String reason, double value, String date, {required bool isGain}) {
    final color = isGain ? AppColors.success : AppColors.error;
    final sign  = isGain ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reason.toLowerCase().capitalize(),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13)),
                Text(date, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
          Text('$sign${value.toStringAsFixed(1)} pts',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.grey.shade400, size: 20),
        const SizedBox(width: 12),
        Text(msg, style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13)),
      ]),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: AppTypography.label);
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Impossible de charger les données', style: GoogleFonts.poppins(color: AppColors.textLight)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

// Extension utilitaire pour capitalize
extension StringCapitalize on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
