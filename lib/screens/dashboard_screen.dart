import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/license_service.dart';
import '../services/database_service.dart';
import '../services/export_excel_service.dart';
import '../services/scheduled_backup_service.dart';
import '../models/license_info.dart';
import 'activation_screen.dart';
import 'import_screen.dart';
import 'reports_screen.dart';
import 'tax_screen.dart';
import 'financial_records_screen.dart';
import 'sync_screen.dart';
import 'predictions_screen.dart';
import 'suppliers_screen.dart';
import 'onat_declaration_screen.dart';
import 'budget_screen.dart';
import 'onat_advanced_screen.dart';
import 'cashflow_screen.dart';
import 'payroll_screen.dart';
import 'assets_screen.dart';
import 'bulk_inventory_screen.dart';
import 'settings_screen.dart';
import 'analytics_screen.dart';
import 'audit_log_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  LicenseInfo? _license;
  Map<String, dynamic>? _chartData;
  bool _loading = true;
  String? _errorMessage;
  int _selectedIndex = 0;

  double _totalIncome = 0;
  double _totalExpenses = 0;
  int _upcomingTaxDeadlines = 0;
  int _totalEmployees = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    ScheduledBackupService.startIfEnabled();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _doLoad().timeout(const Duration(seconds: 15));
    } catch (e) {
      setState(() => _errorMessage = 'Error al cargar los datos: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doLoad() async {
    try {
      _license = await LicenseService.getStoredInfo();
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ActivationScreen()),
        );
        return;
      }
    }

    try {
      final today = DateTime.now();
      final spots = <FlSpot>[];
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final total = await DatabaseService.getTotalByType('income', dateStr, dateStr);
        spots.add(FlSpot((6 - i).toDouble(), total));
      }
      _chartData = {'spots': spots};
    } catch (_) {
      _chartData = {'spots': <FlSpot>[]};
    }

    try {
      final now = DateTime.now();
      final monthStart = DateFormat('yyyy-MM-01').format(now);
      final monthEnd = DateFormat('yyyy-MM-31').format(now);
      _totalIncome = await DatabaseService.getTotalByType('income', monthStart, monthEnd);
      _totalExpenses = await DatabaseService.getTotalByType('expense', monthStart, monthEnd);

      final employees = await DatabaseService.getEmployees();
      _totalEmployees = employees.length;

      final upcoming = await DatabaseService.getCashflowProjection(
        DateFormat('yyyy-MM').format(DateTime.now().add(const Duration(days: 30))),
      );
      _upcomingTaxDeadlines = upcoming != null ? 1 : 0;
    } catch (_) {}
  }

  Future<void> _refreshData() async => _loadData();

  void _logout() {
    LicenseService.deactivate();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ActivationScreen()),
    );
  }

  Widget _pageForIndex(int index) {
    switch (index) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const BulkInventoryScreen();
      case 2:
        return const ImportScreen();
      case 3:
        return const ReportsScreen();
      case 4:
        return const TaxScreen();
      case 5:
        return const OnatAdvancedScreen();
      case 6:
        return const FinancialRecordsScreen();
      case 7:
        return const PayrollScreen();
      case 8:
        return const AssetsScreen();
      case 9:
        return const SuppliersScreen();
      case 10:
        return const BudgetScreen();
      case 11:
        return const PredictionsScreen();
      case 12:
        return const AnalyticsScreen();
      case 13:
        return const SyncScreen();
      case 14:
        return const SettingsScreen();
      case 15:
        return const AuditLogScreen();
      default:
        return _buildDashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_license?.ownerName ?? 'MIPYME Windows'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData, tooltip: 'Actualizar'),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Desactivar'),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.store, size: 36),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Inicio')),
              NavigationRailDestination(icon: Icon(Icons.inventory), label: Text('Inventario')),
              NavigationRailDestination(icon: Icon(Icons.upload_file), label: Text('Importar')),
              NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Reportes')),
              NavigationRailDestination(icon: Icon(Icons.account_balance), label: Text('Impuestos')),
              NavigationRailDestination(icon: Icon(Icons.badge), label: Text('ONAT')),
              NavigationRailDestination(icon: Icon(Icons.receipt), label: Text('Registros')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('Nóminas')),
              NavigationRailDestination(icon: Icon(Icons.business), label: Text('Activos')),
              NavigationRailDestination(icon: Icon(Icons.local_shipping), label: Text('Proveedores')),
              NavigationRailDestination(icon: Icon(Icons.account_balance_wallet), label: Text('Presup.')),
              NavigationRailDestination(icon: Icon(Icons.insights), label: Text('Predic.')),
              NavigationRailDestination(icon: Icon(Icons.analytics), label: Text('Analítica')),
              NavigationRailDestination(icon: Icon(Icons.sync), label: Text('Sincr.')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Config.')),
              NavigationRailDestination(icon: Icon(Icons.security), label: Text('Auditoría')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _pageForIndex(_selectedIndex)),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return _errorMessage != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _refreshData, child: const Text('Reintentar')),
              ],
            ),
          )
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
                        Text('Bienvenido, ${_license?.ownerName ?? "Usuario"}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Plan: ${_license?.planType ?? "N/A"}'),
                        if (_license != null)
                          Text('Vence: ${_license!.expiryDate.toLocal().toString().substring(0, 10)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildKpiCard('Ingresos del mes', '\$${_totalIncome.toStringAsFixed(0)}', Icons.arrow_upward, Colors.green),
                    const SizedBox(width: 12),
                    _buildKpiCard('Gastos del mes', '\$${_totalExpenses.toStringAsFixed(0)}', Icons.arrow_downward, Colors.red),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildKpiCard('Ganancia neta', '\$${(_totalIncome - _totalExpenses).toStringAsFixed(0)}',
                        Icons.account_balance_wallet, Colors.blue),
                    const SizedBox(width: 12),
                    _buildKpiCard('Empleados', '$_totalEmployees', Icons.people, Colors.orange),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildKpiCard(
                      _upcomingTaxDeadlines > 0 ? '¡Vencimientos!' : 'Próx. vencimientos',
                      _upcomingTaxDeadlines > 0 ? '$_upcomingTaxDeadlines' : '0',
                      _upcomingTaxDeadlines > 0 ? Icons.notification_important : Icons.notifications_none,
                      _upcomingTaxDeadlines > 0 ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
                const SizedBox(height: 24),
                if (_chartData != null && (_chartData!['spots'] as List).isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ingresos (últimos 7 días)', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 220,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: (_chartData!['spots'] as List<FlSpot>)
                                        .fold(0.0, (max, s) => s.y > max ? s.y : max) *
                                    1.2,
                                barGroups: (_chartData!['spots'] as List<FlSpot>)
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
                                      getTitlesWidget: (value, meta) =>
                                          Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10)),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final date =
                                            DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                                        return Text(DateFormat('dd/MM').format(date),
                                            style: const TextStyle(fontSize: 10));
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
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const Text('Acciones rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _buildButton(Icons.upload_file, 'Importar datos (.mipyme)', () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen()))),
                const SizedBox(height: 12),
                _buildButton(Icons.inventory, 'Carga masiva de inventario', () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkInventoryScreen()))),
                const SizedBox(height: 12),
                _buildButton(Icons.bar_chart, 'Reportes financieros', () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
                const SizedBox(height: 12),
                _buildButton(Icons.table_chart, 'Exportar a Excel', () async {
                  try {
                    final path = await ExportExcelService.exportFinancialRecordsToExcel();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Excel exportado a: $path')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }),
              ],
            ),
          );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
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