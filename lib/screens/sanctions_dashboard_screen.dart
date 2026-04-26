import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/sanctions_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_system.dart';

class SanctionsDashboardScreen extends StatefulWidget {
  final String userRole;

  const SanctionsDashboardScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  _SanctionsDashboardScreenState createState() => _SanctionsDashboardScreenState();
}

class _SanctionsDashboardScreenState extends State<SanctionsDashboardScreen> {
  final SanctionsService _sanctionsService = SanctionsService();
  
  String _selectedPeriod = '6months';
  String _selectedType = 'All';
  
  List<Map<String, dynamic>> _chartData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final typeQuery = _selectedType == 'All' ? null : _getSanctionTypeKey(_selectedType);
      final data = await _sanctionsService.getSanctionStats(
        period: _selectedPeriod,
        type: typeQuery,
      );
      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getSanctionTypeKey(String displayString) {
    switch (displayString) {
      case 'Renvoi': return 'renvoi';
      case 'Renvoi Prolongé': return 'renvoi_prolonge';
      case 'Sans Questionnaire': return 'sans_questionnaire';
      case 'Absence Continue': return 'absence_continue';
      case 'Maladie': return 'maladie';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanctions Dashboard'),
        backgroundColor: AppColors.adminPrimary,
        actions: [
          if (widget.userRole == 'HR_ADMIN')
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Upload Sanctions Data',
              onPressed: () {
                // Implement upload logic using sanctions_service
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: TextStyle(color: AppColors.error)))
                    : _chartData.isEmpty
                        ? const Center(child: Text('No data available for selected filter.'))
                        : Padding(
                            padding: const EdgeInsets.all(AppSpacing.l),
                            child: _buildChart(),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.s,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select period', style: AppTypography.label.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: _selectedPeriod,
                    items: const [
                      DropdownMenuItem(value: '3months', child: Text('Last 3 Months')),
                      DropdownMenuItem(value: '6months', child: Text('Last 6 Months')),
                      DropdownMenuItem(value: '12months', child: Text('Last 12 Months')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPeriod = val);
                        _fetchData();
                      }
                    },
                    underline: Container(height: 1, color: AppColors.adminPrimary),
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select sanction type', style: AppTypography.label.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Types')),
                      DropdownMenuItem(value: 'Renvoi', child: Text('Renvoi')),
                      DropdownMenuItem(value: 'Renvoi Prolongé', child: Text('Renvoi Prolongé')),
                      DropdownMenuItem(value: 'Sans Questionnaire', child: Text('Sans Questionnaire')),
                      DropdownMenuItem(value: 'Absence Continue', child: Text('Absence Continue')),
                      DropdownMenuItem(value: 'Maladie', child: Text('Maladie')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedType = val);
                        _fetchData();
                      }
                    },
                    underline: Container(height: 1, color: AppColors.adminPrimary),
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.adminPrimary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list, size: 16, color: AppColors.adminPrimary),
                const SizedBox(width: 8),
                Text(
                  'Showing: ${_selectedType == "All" ? "All Types" : _selectedType} \u2022 Last ${_selectedPeriod.replaceAll("months", " Months")}',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.adminPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_selectedType != 'All') {
      return _buildSingleBarChart();
    } else {
      return _buildMultiBarChart();
    }
  }

  Widget _buildSingleBarChart() {
    final double maxY = _chartData.fold<double>(
      0,
      (max, e) => (e['value'] as num).toDouble() > max ? (e['value'] as num).toDouble() : max,
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 10 : maxY + (maxY * 0.2), // add 20% padding to top
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${_chartData[group.x.toInt()]['month']}\n${rod.toY.round()} sanctions',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _chartData.length) {
                  final monthStr = _chartData[value.toInt()]['month'].toString();
                  // Format 'YYYY-MM' -> 'MM/YY' or just 'MM'
                  final parts = monthStr.split('-');
                  final display = parts.length == 2 ? '${parts[1]}/${parts[0].substring(2)}' : monthStr;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(display, style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_chartData.length, (index) {
          final val = (_chartData[index]['value'] as num).toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: AppColors.adminPrimary,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMultiBarChart() {
    // If "All" is selected, we can show a stacked bar chart or grouped. Grouped is cleaner.
    final double maxY = _chartData.fold<double>(
      0,
      (max, e) {
        double m1 = (e['renvoi'] as num).toDouble();
        double m2 = (e['renvoi_prolonge'] as num).toDouble();
        double m3 = (e['sans_questionnaire'] as num).toDouble();
        double m4 = (e['absence_continue'] as num).toDouble();
        double m5 = (e['maladie'] as num).toDouble();
        double localMax = [m1, m2, m3, m4, m5].reduce((a, b) => a > b ? a : b);
        return localMax > max ? localMax : max;
      },
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 10 : maxY + (maxY * 0.2),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _chartData.length) {
                  final monthStr = _chartData[value.toInt()]['month'].toString();
                  final parts = monthStr.split('-');
                  final display = parts.length == 2 ? '${parts[1]}/${parts[0].substring(2)}' : monthStr;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(display, style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_chartData.length, (index) {
          final e = _chartData[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              _buildRod((e['renvoi'] as num).toDouble(), Colors.red),
              _buildRod((e['renvoi_prolonge'] as num).toDouble(), Colors.deepOrange),
              _buildRod((e['sans_questionnaire'] as num).toDouble(), Colors.amber),
              _buildRod((e['absence_continue'] as num).toDouble(), Colors.blue),
              _buildRod((e['maladie'] as num).toDouble(), Colors.green),
            ],
          );
        }),
      ),
    );
  }

  BarChartRodData _buildRod(double value, Color color) {
    return BarChartRodData(
      toY: value,
      color: color,
      width: 6,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
    );
  }
}
