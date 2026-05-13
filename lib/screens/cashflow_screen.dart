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

  // Proyecciones
  final _projIncomeCtrl = TextEditingController();
  final _projExpenseCtrl = TextEditingController();
  double? _projectedIncome;
  double? _projectedExpenses;

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

    // Cargar proyección si existe
    final proj = await DatabaseService.getCashflowProjection(monthStr);
    if (proj != null) {
      _projectedIncome = proj['projected_income'] as double;
      _projectedExpenses = proj['projected_expenses'] as double;
      _projIncomeCtrl.text = _projectedIncome!.toString();
      _projExpenseCtrl.text = _projectedExpenses!.toString();
    } else {
      _projectedIncome = null;
      _projectedExpenses = null;
      _projIncomeCtrl.clear();
      _projExpenseCtrl.clear();
    }

    setState(() {
      _incomeSpots = incomeSpots;
      _expenseSpots = expenseSpots;
      _totalIncome = totalIncome;
      _totalExpenses = totalExpenses;
      _loading = false;
    });
  }

  Future<void> _saveProjection() async {
    final income = double.tryParse(_projIncomeCtrl.text) ?? 0;
    final expenses = double.tryParse(_projExpenseCtrl.text) ?? 0;
    final month = _monthFormat.format(_selectedDate);
    await DatabaseService.saveCashflowProjection(month, income, expenses);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proyección guardada')),
      );
    }
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

                  // Proyección
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Proyección del mes',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _projIncomeCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Ingresos esperados',
                                    border: OutlineInputBorder(),
                                    prefixText: '\$ ',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _projExpenseCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Gastos esperados',
                                    border: OutlineInputBorder(),
                                    prefixText: '\$ ',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: _saveProjection,
                              icon: const Icon(Icons.save, size: 18),
                              label: const Text('Guardar proyección'),
                            ),
                          ),
                          if (_projectedIncome != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildComparison(
                                    'Ingresos', _projectedIncome!, _totalIncome),
                                const SizedBox(width: 12),
                                _buildComparison(
                                    'Gastos', _projectedExpenses!, _totalExpenses),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
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

  Widget _buildComparison(String label, double projected, double real) {
    final diff = real - projected;
    final color = diff >= 0 ? Colors.green : Colors.red;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text('Proy: \$${projected.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
          Text('Real: \$${real.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
          Text(
            '${diff >= 0 ? '+' : ''}\$${diff.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
