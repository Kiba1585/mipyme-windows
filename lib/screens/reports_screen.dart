import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/report_service.dart';
import '../services/export_service.dart';
import '../models/financial_data.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DateFormat _monthFormat = DateFormat('yyyy-MM');
  DateTime _selectedDate = DateTime.now();
  double _totalSales = 0;
  double _totalExpenses = 0;
  double _netProfit = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final monthStr = _monthFormat.format(_selectedDate);
    final startDate = '$monthStr-01';
    final endDate = '$monthStr-31';

    final sales = await DatabaseService.getTotalByType('income', startDate, endDate);
    final expenses = await DatabaseService.getTotalByType('expense', startDate, endDate);

    setState(() {
      _totalSales = sales;
      _totalExpenses = expenses;
      _netProfit = sales - expenses;
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

  Future<void> _exportPdf() async {
    final dailySales = <DailySales>[]; // simplificado, podrías obtener datos diarios
    final report = ReportService.calculateMonthly(
      _monthFormat.format(_selectedDate),
      dailySales,
      _totalExpenses,
    );
    await ReportService.exportMonthlyPdf(report);
  }

  Future<void> _exportCsv() async {
    try {
      final path = await ExportService.exportFinancialRecordsToCsv();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV exportado a: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthStr = _monthFormat.format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes financieros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickMonth,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mes: $monthStr',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Tarjetas de resumen
                  Row(
                    children: [
                      _buildSummaryCard(
                        'Ingresos',
                        '\$${_totalSales.toStringAsFixed(2)}',
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Gastos',
                        '\$${_totalExpenses.toStringAsFixed(2)}',
                        Colors.red,
                        Icons.arrow_downward,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryCard(
                    'Ganancia Neta',
                    '\$${_netProfit.toStringAsFixed(2)}',
                    _netProfit >= 0 ? Colors.blue : Colors.red,
                    Icons.account_balance_wallet,
                  ),

                  const Spacer(),

                  // Botones de exportación
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar PDF'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _exportCsv,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Exportar a CSV (Excel)'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}