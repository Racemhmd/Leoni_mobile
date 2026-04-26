import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/sanctions_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_system.dart';

class HrKpiDashboardScreen extends StatefulWidget {
  final String userRole;
  
  const HrKpiDashboardScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  State<HrKpiDashboardScreen> createState() => _HrKpiDashboardScreenState();
}

class _HrKpiDashboardScreenState extends State<HrKpiDashboardScreen> {
  final SanctionsService _sanctionsService = SanctionsService();
  
  List<Map<String, dynamic>> _employees = [];
  bool _isLoadingEmployees = true;

  bool _isLoadingData = true;
  String? _errorMessage;
  
  Map<String, dynamic> _dashboardData = {'totals': {}, 'chartData': []};
  
  String _selectedPeriod = '6'; // 3, 6, 12 months
  String? _selectedMatricule;
  String _selectedChartFilter = 'All'; // Chart filter

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _fetchDashboardData();
  }

  void _fetchEmployees() async {
    try {
      final employees = await _sanctionsService.getAllEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
          _isLoadingEmployees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEmployees = false);
      }
    }
  }

  void _fetchDashboardData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final data = await _sanctionsService.getKpiDashboardData(
        period: _selectedPeriod,
        matricule: _selectedMatricule,
      );
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingData = false;
        });
      }
    }
  }

  void _onFilterChanged() {
    _fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final isGroupView = _selectedMatricule == null || _selectedMatricule!.isEmpty;
    final viewTitle = isGroupView ? 'Group KPI View' : 'Employee KPI View';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('HR KPI Dashboard'),
        backgroundColor: AppColors.adminPrimary,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoadingData
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)))
                    : RefreshIndicator(
                        onRefresh: () async => _fetchDashboardData(),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.l),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(viewTitle, style: AppTypography.headerMedium),
                              const SizedBox(height: AppSpacing.m),
                              _buildKpiGrid(),
                              const SizedBox(height: AppSpacing.xl),
                              Text('Evolution Over Time', style: AppTypography.headerSmall),
                              const SizedBox(height: AppSpacing.m),
                              _buildChartSection(),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _isLoadingEmployees
                    ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : Autocomplete<Map<String, dynamic>>(
                        displayStringForOption: (option) => '${option['matricule']} - ${option['fullName'] ?? 'Unknown'}',
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) return const Iterable.empty();
                          return _employees.where((employee) {
                            final matricule = employee['matricule']?.toString().toLowerCase() ?? '';
                            final name = (employee['fullName'] ?? '').toString().toLowerCase();
                            final query = textEditingValue.text.toLowerCase();
                            return matricule.contains(query) || name.contains(query);
                          });
                        },
                        onSelected: (Map<String, dynamic> selection) {
                          setState(() => _selectedMatricule = selection['matricule'].toString());
                          _onFilterChanged();
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Search Employee...',
                              prefixIcon: const Icon(Icons.person_search, size: 20),
                              suffixIcon: _selectedMatricule != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        controller.clear();
                                        setState(() => _selectedMatricule = null);
                                        _onFilterChanged();
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: '3', child: Text('3 Months')),
                    DropdownMenuItem(value: '6', child: Text('6 Months')),
                    DropdownMenuItem(value: '12', child: Text('12 Months')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPeriod = val);
                      _onFilterChanged();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    final totals = _dashboardData['totals'] ?? {};
    final sanctions = totals['sanctions'] ?? 0;
    final absences = totals['absences'] ?? 0;
    final delays = totals['delays'] ?? 0;
    final sickDays = totals['sickDays'] ?? 0;
    final dismissals = totals['dismissals'] ?? 0;
    final extendedDismissals = totals['extendedDismissals'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      crossAxisSpacing: AppSpacing.m,
      mainAxisSpacing: AppSpacing.m,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildKpiCard('Total Sanctions', sanctions, Icons.gavel, AppColors.error),
        _buildKpiCard('Absences', absences, Icons.event_busy, Colors.orange),
        _buildKpiCard('Delays (Minor)', delays, Icons.watch_later, Colors.blue),
        _buildKpiCard('Sick Days', sickDays, Icons.medical_services, Colors.green),
        _buildKpiCard('Dismissals', dismissals, Icons.person_off, Colors.red[900]!),
        _buildKpiCard('Extended Diss.', extendedDismissals, Icons.block, Colors.purple),
      ],
    );
  }

  Widget _buildKpiCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value.toString(), style: AppTypography.headerMedium.copyWith(color: AppColors.textPrimary)),
                Text(title, style: AppTypography.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    final List<dynamic> chartDataRaw = _dashboardData['chartData'] ?? [];
    if (chartDataRaw.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text('No data to display')));
    }

    double maxY = 1.0;
    for (var monthData in chartDataRaw) {
      double sum = 0;
      if (_selectedChartFilter == 'All') {
        sum = (monthData['renvoi'] ?? 0) +
            (monthData['renvoi_prolonge'] ?? 0) +
            (monthData['delays'] ?? 0) +
            (monthData['absences'] ?? 0) +
            (monthData['sickDays'] ?? 0).toDouble();
      } else {
        sum = (monthData[_selectedChartFilter] ?? 0).toDouble();
      }
      if (sum > maxY) maxY = sum;
    }

    return Container(
      height: 350,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DropdownButton<String>(
                value: _selectedChartFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Types')),
                  DropdownMenuItem(value: 'sickDays', child: Text('Sick Days')),
                  DropdownMenuItem(value: 'absences', child: Text('Absences')),
                  DropdownMenuItem(value: 'delays', child: Text('Delays')),
                  DropdownMenuItem(value: 'renvoi', child: Text('Dismissals')),
                  DropdownMenuItem(value: 'renvoi_prolonge', child: Text('Ext. Dismissals')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedChartFilter = val);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY + 1,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= chartDataRaw.length) return const SizedBox();
                        final monthStr = chartDataRaw[value.toInt()]['month']?.toString() ?? '';
                        if (monthStr.length < 7) return const SizedBox();
                        final parts = monthStr.split('-');
                        final label = '${parts[1]}/${parts[0].substring(2)}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox();
                        return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(chartDataRaw.length, (index) {
                  final data = chartDataRaw[index];
                  
                  if (_selectedChartFilter != 'All') {
                    final val = (data[_selectedChartFilter] ?? 0).toDouble();
                    Color barColor = AppColors.primary;
                    switch(_selectedChartFilter) {
                      case 'sickDays': barColor = Colors.green; break;
                      case 'absences': barColor = Colors.orange; break;
                      case 'delays': barColor = Colors.blue; break;
                      case 'renvoi': barColor = Colors.red[900]!; break;
                      case 'renvoi_prolonge': barColor = Colors.purple; break;
                    }
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          color: barColor,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ]
                    );
                  }

                  return BarChartGroupData(
                    x: index,
                    barsSpace: 2,
                    barRods: [
                      // Using stacked bars for a clear unified view
                      BarChartRodData(
                        toY: (data['renvoi'] ?? 0) +
                             (data['renvoi_prolonge'] ?? 0) +
                             (data['delays'] ?? 0) +
                             (data['absences'] ?? 0) +
                             (data['sickDays'] ?? 0).toDouble(),
                        color: Colors.transparent, // the actual bar is transparent
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                        rodStackItems: [
                           BarChartRodStackItem(0, (data['sickDays'] ?? 0).toDouble(), Colors.green),
                           BarChartRodStackItem(
                               (data['sickDays'] ?? 0).toDouble(),
                               (data['sickDays'] ?? 0) + (data['absences'] ?? 0).toDouble(),
                               Colors.orange
                           ),
                           BarChartRodStackItem(
                               (data['sickDays'] ?? 0) + (data['absences'] ?? 0).toDouble(),
                               (data['sickDays'] ?? 0) + (data['absences'] ?? 0) + (data['delays'] ?? 0).toDouble(),
                               Colors.blue
                           ),
                           BarChartRodStackItem(
                               (data['sickDays'] ?? 0) + (data['absences'] ?? 0) + (data['delays'] ?? 0).toDouble(),
                               (data['sickDays'] ?? 0) + (data['absences'] ?? 0) + (data['delays'] ?? 0) + (data['renvoi'] ?? 0).toDouble(),
                               Colors.red[900]!
                           ),
                           BarChartRodStackItem(
                               (data['sickDays'] ?? 0) + (data['absences'] ?? 0) + (data['delays'] ?? 0) + (data['renvoi'] ?? 0).toDouble(),
                               (data['sickDays'] ?? 0) + (data['absences'] ?? 0) + (data['delays'] ?? 0) + (data['renvoi'] ?? 0) + (data['renvoi_prolonge'] ?? 0).toDouble(),
                               Colors.purple
                           ),
                        ]
                      )
                    ],
                  );
                }),
              ),
            ),
          ),
          if (_selectedChartFilter == 'All') ...[
            const SizedBox(height: AppSpacing.m),
            _buildChartLegend(),
          ]
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _legendItem(Colors.green, 'Sick'),
        _legendItem(Colors.orange, 'Absence'),
        _legendItem(Colors.blue, 'Delay'),
        _legendItem(Colors.red[900]!, 'Dismissal'),
        _legendItem(Colors.purple, 'Ext. Dismissal'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
