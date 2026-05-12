import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/license_service.dart';
import '../services/database_service.dart';
import '../models/license_info.dart';
import 'import_screen.dart';
import 'reports_screen.dart';
import 'tax_screen.dart';
import 'financial_records_screen.dart';
import 'sync_screen.dart';
import 'predictions_screen.dart';
import 'activation_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  LicenseInfo? _license;
  Map<String, dynamic>? _chartData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final license = await LicenseService.getStoredInfo();

    // Cargar datos para el gráfico (últimos 7 días)
    final today = DateTime.now();
    final spots = <FlSpot>[];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final total = await DatabaseService.getTotalByType('income', dateStr, dateStr);
      spots.add(FlSpot((6 - i).toDouble(), total));
    }

    setState(() {
      _license = license;
      _chartData = {'spots': spots};
      _loading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() => _loading = true);
    await _loadData();
  }

  void _logout() {
    LicenseService.deactivate();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ActivationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_license?.ownerName ?? 'MIPYME Windows'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Actualizar datos',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Desactivar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de la licencia
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenido, ${_license?.ownerName ?? "Usuario"}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Plan: ${_license?.planType ?? "N/A"}'),
                          if (_license != null)
                            Text('Vence: ${_license!.expiryDate.toLocal().toString().substring(0, 10)}'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Gráfico de barras (últimos 7 días)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ingresos (últimos 7 días)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 220,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: (_chartData?['spots'] as List<FlSpot>)
                                        .fold(0.0, (max, s) => s.y > max ? s.y : max) *
                                    1.2,
                                barGroups: (_chartData?['spots'] as List<FlSpot>)
                                    .map((spot) => BarChartGroupData(
                                          x: spot.x.toInt(),
                                          barRods: [
                                            BarChartRodData(
                                              toY: spot.y,
                                              color: Colors.blue,
                                              width: 22,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ],
                                        ))
                                    .toList(),
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
                                        final date = DateTime.now()
                                            .subtract(Duration(days: 6 - value.toInt()));
                                        return Text(
                                          DateFormat('dd/MM').format(date),
                                          style: const TextStyle(fontSize: 10),
                                        );
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

                  // Acciones rápidas
                  const Text('Acciones rápidas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),

                  _buildButton(Icons.upload_file, 'Importar datos (.mipyme)', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ImportScreen()));
                  }),
                  const SizedBox(height: 12),

                  _buildButton(Icons.bar_chart, 'Reportes financieros', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ReportsScreen()));
                  }),
                  const SizedBox(height: 12),

                  _buildButton(Icons.account_balance, 'Impuestos (ONAT)', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const TaxScreen()));
                  }),
                  const SizedBox(height: 12),

                  _buildButton(Icons.receipt, 'Registros financieros', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FinancialRecordsScreen()));
                  }),
                  const SizedBox(height: 12),

                  _buildButton(Icons.insights, 'Predicciones', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PredictionsScreen()));
                  }),
                  const SizedBox(height: 12),

                  _buildButton(Icons.sync, 'Sincronizar con móvil', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SyncScreen()));
                  }),

                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'v1.0.0 - Complemento Windows',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildButton(IconData icon, String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}