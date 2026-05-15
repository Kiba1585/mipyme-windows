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

  // --- Secciones de la barra lateral (mismo orden que el índice) ---
  final List<_NavGroup> _navGroups = [
    _NavGroup('Principal', [
      _NavItem(Icons.dashboard, 'Inicio'),
      _NavItem(Icons.inventory, 'Inventario'),
      _NavItem(Icons.upload_file, 'Importar'),
    ]),
    _NavGroup('Finanzas', [
      _NavItem(Icons.bar_chart, 'Reportes'),
      _NavItem(Icons.account_balance, 'Impuestos'),
      _NavItem(Icons.badge, 'ONAT'),
      _NavItem(Icons.receipt, 'Registros'),
      _NavItem(Icons.account_balance_wallet, 'Presupuesto'),
      _NavItem(Icons.insights, 'Predicciones'),
      _NavItem(Icons.analytics, 'Analítica'),
    ]),
    _NavGroup('Recursos', [
      _NavItem(Icons.people, 'Nóminas'),
      _NavItem(Icons.business, 'Activos'),
      _NavItem(Icons.local_shipping, 'Proveedores'),
    ]),
    _NavGroup('Sistema', [
      _NavItem(Icons.sync, 'Sincronizar'),
      _NavItem(Icons.settings, 'Configuración'),
      _NavItem(Icons.security, 'Auditoría'),
    ]),
  ];

  // Mapa plano de índice -> screen builder
  late final Map<int, WidgetBuilder> _pages = {
    0: (_) => _buildDashboardContent(),
    1: (_) => const BulkInventoryScreen(),
    2: (_) => const ImportScreen(),
    3: (_) => const ReportsScreen(),
    4: (_) => const TaxScreen(),
    5: (_) => const OnatAdvancedScreen(),
    6: (_) => const FinancialRecordsScreen(),
    7: (_) => const BudgetScreen(),
    8: (_) => const PredictionsScreen(),
    9: (_) => const AnalyticsScreen(),
    10: (_) => const PayrollScreen(),
    11: (_) => const AssetsScreen(),
    12: (_) => const SuppliersScreen(),
    13: (_) => const SyncScreen(),
    14: (_) => const SettingsScreen(),
    15: (_) => const AuditLogScreen(),
  };

  int _flatIndex(int groupIdx, int itemIdx) {
    int count = 0;
    for (int i = 0; i < groupIdx; i++) {
      count += _navGroups[i].items.length;
    }
    return count + itemIdx;
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_license?.ownerName ?? 'MIPYME Windows'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData, tooltip: 'Actualizar'),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Cambiar de dueño'),
        ],
      ),
      body: Row(
        children: [
          // --- Barra lateral con secciones ---
          SizedBox(
            width: 220,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Icon(Icons.store, size: 36),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: _navGroups.asMap().entries.map((groupEntry) {
                        final groupIdx = groupEntry.key;
                        final group = groupEntry.value;
                        return ExpansionTile(
                          initiallyExpanded: true,
                          leading: Icon(group.items.first.icon),
                          title: Text(group.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          children: group.items.asMap().entries.map((itemEntry) {
                            final itemIdx = itemEntry.key;
                            final item = itemEntry.value;
                            final flatIdx = _flatIndex(groupIdx, itemIdx);
                            final selected = flatIdx == _selectedIndex;
                            return ListTile(
                              leading: Icon(item.icon, color: selected ? Theme.of(context).colorScheme.primary : null),
                              title: Text(item.label, style: TextStyle(
                                color: selected ? Theme.of(context).colorScheme.primary : null,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              )),
                              selected: selected,
                              onTap: () => setState(() => _selectedIndex = flatIdx),
                              dense: true,
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Cambiar de dueño', style: TextStyle(color: Colors.red)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_pages[_selectedIndex] ?? (_) => const SizedBox())(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() { /* ... exactamente igual que antes ... */ }
  // (El resto del código del dashboard no se modifica, por brevedad lo omito)
  // Debes conservar los métodos _buildKpiCard, _buildButton y el contenido del panel.
}

class _NavGroup {
  final String title;
  final List<_NavItem> items;
  _NavGroup(this.title, this.items);
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}