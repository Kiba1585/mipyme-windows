import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../services/data_import_service.dart';
import '../models/financial_data.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  MonthlyReport? _report;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final localData = await DataImportService.loadLocalData();
    if (localData == null) return;

    // Simular datos de ejemplo (luego se reemplazará con datos reales del archivo)
    final dailySales = <DailySales>[
      DailySales(date: '2026-05-01', total: 1500, cash: 1000, transfer: 500, tickets: 15),
      DailySales(date: '2026-05-02', total: 2000, cash: 1200, transfer: 800, tickets: 20),
    ];
    final expenses = 500.0;

    setState(() {
      _report = ReportService.calculateMonthly('2026-05', dailySales, expenses);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes financieros')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _report == null
            ? const Center(child: Text('Importe datos primero'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mes: ${_report!.month}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  Text('Ventas: \$${_report!.totalSales.toStringAsFixed(2)}'),
                  Text('Gastos: \$${_report!.expenses.toStringAsFixed(2)}'),
                  const Divider(),
                  Text('Ganancia Neta: \$${_report!.netProfit.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => ReportService.exportMonthlyPdf(_report!),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar PDF'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}