import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';                     // ← añadido
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<CategoryExpense> _expensesByCategory = [];
  List<MonthlyTrend> _monthlyTrends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final monthStart = '${DateFormat('yyyy-MM').format(now)}-01';
    final monthEnd = '${DateFormat('yyyy-MM').format(now)}-31';
    _expensesByCategory = await AnalyticsService.getExpensesByCategory(
      startDate: monthStart,
      endDate: monthEnd,
    );
    _monthlyTrends = await AnalyticsService.getMonthlyTrend();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis avanzado')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gastos por categoría (mes actual)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                sections: _expensesByCategory.map((cat) {
                                  final percent = _expensesByCategory.isNotEmpty
                                      ? cat.amount / _expensesByCategory.fold(0.0, (sum, e) => sum + e.amount)
                                      : 0.0;
                                  return PieChartSectionData(
                                    value: percent * 100,
                                    title: '${(percent * 100).toStringAsFixed(0)}%',
                                    color: _getCategoryColor(cat.category),
                                    radius: 80,
                                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                                  );
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: _expensesByCategory.map((cat) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12, height: 12,
                                    color: _getCategoryColor(cat.category),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(cat.category, style: const TextStyle(fontSize: 12)),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tendencia anual (ingresos vs gastos)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child: LineChart(
                              LineChartData(
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _monthlyTrends.asMap().entries.map((e) {
                                      return FlSpot(e.key.toDouble(), e.value.income);
                                    }).toList(),
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: _monthlyTrends.asMap().entries.map((e) {
                                      return FlSpot(e.key.toDouble(), e.value.expenses);
                                    }).toList(),
                                    isCurved: true,
                                    color: Colors.red,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 50,
                                      getTitlesWidget: (value, meta) =>
                                          Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10)),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 && index < _monthlyTrends.length) {
                                          final month = _monthlyTrends[index].month;
                                          return Text(month.substring(5), style: const TextStyle(fontSize: 10));
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _legendItem(Colors.green, 'Ingresos'),
                              const SizedBox(width: 16),
                              _legendItem(Colors.red, 'Gastos'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.amber,
    ];
    final hash = category.hashCode.abs();
    return colors[hash % colors.length];
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}