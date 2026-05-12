import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({super.key});

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
  final DateFormat _monthFormat = DateFormat('yyyy-MM');
  DateTime _selectedDate = DateTime.now();
  List<FlSpot> _incomeSpots = [];
  List<FlSpot> _expenseSpots = [];
  double _totalIncome = 0;
  double _totalExpenses = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final monthStr = _monthFormat.format(_selectedDate);
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    double totalIncome = 0;
    double totalExpenses = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr = '$monthStr-${day.toString().padLeft(2, '0')}';
      final income = await DatabaseService.getTotalByType('income', dateStr, dateStr);
      final expense = await DatabaseService.getTotalByType('expense', dateStr, dateStr);
      incomeSpots.add(FlSpot(day.toDouble(), income));
      expenseSpots.add(FlSpot(day.toDouble(), expense));
      totalIncome += income;
      totalExpenses += expense;
    }

    setState(() {
      _incomeSpots = incomeSpots;
      _expenseSpots = expenseSpots;
      _totalIncome = totalIncome;
      _totalExpenses = totalExpenses;
      _loading = false;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthStr = _monthFormat.format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flujo de Caja'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickMonth),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mes: $monthStr',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Resumen
                  Row(
                    children: [
                      _buildSummaryCard('Ingresos', _totalIncome, Colors.green),
                      const SizedBox(width: 16),
                      _buildSummaryCard('Gastos', _totalExpenses, Colors.red),
                      const SizedBox(width: 16),
                      _buildSummaryCard('Balance', _totalIncome - _totalExpenses,
                          _totalIncome - _totalExpenses >= 0 ? Colors.blue : Colors.red),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Gráfico de líneas
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ingresos vs Gastos (diario)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child: LineChart(
                              LineChartData(
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _incomeSpots,
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: _expenseSpots,
                                    isCurved: true,
                                    color: Colors.red,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 42,
                                      getTitlesWidget: (value, meta) => Text(
                                        '\$${value.toInt()}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final day = value.toInt();
                                        if (day % 5 == 0 || day == 1) {
                                          return Text('$day',
                                              style: const TextStyle(fontSize: 10));
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                              ),
                            ),
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

  Widget _buildSummaryCard(String label, double amount, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}