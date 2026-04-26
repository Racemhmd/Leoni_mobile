import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/sanctions_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_system.dart';

class EmployeeSanctionsHistoryScreen extends StatefulWidget {
  final String userRole;
  
  const EmployeeSanctionsHistoryScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  State<EmployeeSanctionsHistoryScreen> createState() => _EmployeeSanctionsHistoryScreenState();
}

class _EmployeeSanctionsHistoryScreenState extends State<EmployeeSanctionsHistoryScreen> {
  final SanctionsService _sanctionsService = SanctionsService();
  
  List<Map<String, dynamic>> _employees = [];
  bool _isLoadingEmployees = true;

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _historyData = [];
  bool _hasSearched = false;
  
  String _selectedChartType = 'All';
  final List<String> _sanctionTypes = [
    'All',
    'Renvoi',
    'Renvoi Prolongé',
    'Sans Questionnaire',
    'Absence Continue',
    'Maladie'
  ];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
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
        setState(() {
          _isLoadingEmployees = false;
        });
      }
    }
  }

  void _searchEmployee(String matricule) async {
    if (matricule.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final data = await _sanctionsService.getEmployeeHistory(matricule);
      setState(() {
        _historyData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _historyData = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only HR_ADMIN and SUPERVISOR should access this logic, but UI can be protected by parent
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Sanction History'),
        backgroundColor: AppColors.adminPrimary,
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    if (_isLoadingEmployees) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      color: Colors.white,
      child: Autocomplete<Map<String, dynamic>>(
        displayStringForOption: (option) => '${option['matricule']} - ${option['fullName'] ?? option['full_name'] ?? 'Unknown'}',
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return _employees;
          }
          return _employees.where((employee) {
            final matricule = employee['matricule']?.toString().toLowerCase() ?? '';
            final name = (employee['fullName'] ?? employee['full_name'] ?? '').toString().toLowerCase();
            final query = textEditingValue.text.toLowerCase();
            return matricule.contains(query) || name.contains(query);
          });
        },
        onSelected: (Map<String, dynamic> selection) {
          _searchEmployee(selection['matricule'].toString());
        },
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Search employee by matricule or name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)));
    }

    if (_hasSearched && _historyData.isEmpty) {
      return Center(
        child: Text('No sanctions history found for this employee.', style: AppTypography.bodyLarge),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Text('Search by matricule to view sanction history.', style: TextStyle(color: Colors.grey)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildChartSection(),
          const SizedBox(height: AppSpacing.m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Text('Detailed History', style: AppTypography.headerSmall),
          ),
          _buildHistoryTable(),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sanctions Over Time', style: AppTypography.headerSmall),
              DropdownButton<String>(
                value: _selectedChartType,
                underline: const SizedBox(),
                items: _sanctionTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedChartType = val);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          SizedBox(
            height: 250,
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    // 1. Group data by YYYY-MM
    final Map<String, Map<String, int>> monthlyData = {};
    for (var item in _historyData) {
      final fullDate = item['recordDate']?.toString() ?? '';
      if (fullDate.length < 7) continue;
      final month = fullDate.substring(0, 7); // 'YYYY-MM'
      
      monthlyData.putIfAbsent(month, () => {
        'Renvoi': 0, 'Renvoi Prolongé': 0, 'Sans Questionnaire': 0, 'Absence Continue': 0, 'Maladie': 0
      });
      
      monthlyData[month]!['Renvoi'] = (monthlyData[month]!['Renvoi'] ?? 0) + (int.tryParse(item['renvoi']?.toString() ?? '0') ?? 0);
      monthlyData[month]!['Renvoi Prolongé'] = (monthlyData[month]!['Renvoi Prolongé'] ?? 0) + (int.tryParse(item['renvoi_prolonge']?.toString() ?? '0') ?? 0);
      monthlyData[month]!['Sans Questionnaire'] = (monthlyData[month]!['Sans Questionnaire'] ?? 0) + (int.tryParse(item['sans_questionnaire']?.toString() ?? '0') ?? 0);
      monthlyData[month]!['Absence Continue'] = (monthlyData[month]!['Absence Continue'] ?? 0) + (int.tryParse(item['absence_continue']?.toString() ?? '0') ?? 0);
      monthlyData[month]!['Maladie'] = (monthlyData[month]!['Maladie'] ?? 0) + (int.tryParse(item['maladie']?.toString() ?? '0') ?? 0);
    }

    final sortedMonths = monthlyData.keys.toList()..sort();
    if (sortedMonths.isEmpty) return const Center(child: Text('Not enough data to plot'));

    // Determine max Y value
    double maxY = 1.0;
    for (var month in sortedMonths) {
      if (_selectedChartType == 'All') {
        final sum = monthlyData[month]!.values.fold(0, (a, b) => a + b);
        if (sum > maxY) maxY = sum.toDouble();
      } else {
        final val = monthlyData[month]![_selectedChartType] ?? 0;
        if (val > maxY) maxY = val.toDouble();
      }
    }

    return BarChart(
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
                if (value.toInt() < 0 || value.toInt() >= sortedMonths.length) return const Text('');
                final monthStr = sortedMonths[value.toInt()];
                // format YYYY-MM -> MM/YY
                final parts = monthStr.split('-');
                final label = '${parts[1]}/${parts[0].substring(2)}';
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text(label, style: const TextStyle(fontSize: 10)));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const SizedBox();
                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(sortedMonths.length, (index) {
          final monthStr = sortedMonths[index];
          final data = monthlyData[monthStr]!;

          if (_selectedChartType != 'All') {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (data[_selectedChartType] ?? 0).toDouble(),
                  color: AppColors.adminPrimary,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }

          // 'All' shows a stacked or multi bar. Let's do a grouped bar.
          return BarChartGroupData(
            x: index,
            barsSpace: 2,
            barRods: [
              if (data['Renvoi']! > 0) BarChartRodData(toY: data['Renvoi']!.toDouble(), color: Colors.red, width: 8),
              if (data['Renvoi Prolongé']! > 0) BarChartRodData(toY: data['Renvoi Prolongé']!.toDouble(), color: Colors.orange, width: 8),
              if (data['Sans Questionnaire']! > 0) BarChartRodData(toY: data['Sans Questionnaire']!.toDouble(), color: Colors.purple, width: 8),
              if (data['Absence Continue']! > 0) BarChartRodData(toY: data['Absence Continue']!.toDouble(), color: Colors.blue, width: 8),
              if (data['Maladie']! > 0) BarChartRodData(toY: data['Maladie']!.toDouble(), color: Colors.green, width: 8),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHistoryTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Card(
        elevation: 1,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
              columns: const [
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Renvoi', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Renvoi Prolongé', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Sans Question.', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Absence Cont.', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Maladie', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _historyData.map((item) {
                final dateStr = item['recordDate']?.toString().split('T').first ?? '-';
                
                Widget buildCell(dynamic value) {
                  final count = value is num ? value.toInt() : int.tryParse(value?.toString() ?? '0') ?? 0;
                  if (count == 0) {
                    return const Text('0', style: TextStyle(color: Colors.grey));
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(count.toString(), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  );
                }

                return DataRow(cells: [
                  DataCell(Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(buildCell(item['renvoi'])),
                  DataCell(buildCell(item['renvoi_prolonge'])),
                  DataCell(buildCell(item['sans_questionnaire'])),
                  DataCell(buildCell(item['absence_continue'])),
                  DataCell(buildCell(item['maladie'])),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
