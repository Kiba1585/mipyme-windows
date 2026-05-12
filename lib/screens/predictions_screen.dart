import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/prediction_service.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  List<MonthlySummary> _history = [];
  MonthlySummary? _prediction;
  double _trend = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final history = await PredictionService.getMonthlyHistory();
    final prediction = PredictionService.predictNextMonth(history);
    final trend = PredictionService.calculateTrend(history);

    setState(() {
      _history = history;
      _prediction = prediction;
      _trend = trend;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Predicciones y Tendencias')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de tendencia
                  Card(
                    color: _trend >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _trend >= 0 ? Icons.trending_up : Icons.trending_down,
                            size: 40,
                            color: _trend >= 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tendencia (últimos 3 meses)',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '\$${_trend.toStringAsFixed(2)} / mes',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _trend >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Gráfico de historial mensual
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Historial de ganancias (12 meses)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _getMaxProfit() * 1.2,
                                barGroups: _buildBarGroups(),
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
                                        final index = value.toInt();
                                        if (index < _history.length) {
                                          return Text(
                                            _history[index].month.substring(5),
                                            style: const TextStyle(fontSize: 10),
                                          );
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

                  const SizedBox(height: 24),

                  // Predicción del próximo mes
                  if (_prediction != null)
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Predicción próximo mes',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildPredictionStat(
                                    'Ingresos', _prediction!.income, Colors.green),
                                _buildPredictionStat(
                                    'Gastos', _prediction!.expenses, Colors.red),
                                _buildPredictionStat(
                                    'Ganancia', _prediction!.profit, Colors.blue),
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

  double _getMaxProfit() {
    if (_history.isEmpty) return 0;
    return _history.fold(0.0, (max, s) =>
        s.profit.abs() > max.abs() ? s.profit : max).abs();
  }

  List<BarChartGroupData> _buildBarGroups() {
    return _history.asMap().entries.map((entry) {
      final index = entry.key;
      final summary = entry.value;
      final isProfit = summary.profit >= 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: summary.profit.abs(),
            color: isProfit ? Colors.green : Colors.red,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildPredictionStat(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}