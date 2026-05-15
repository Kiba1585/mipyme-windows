import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tax_service.dart';
import '../services/data_import_service.dart';
import '../services/database_service.dart';

class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key});

  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  TaxCalculation? _currentCalc;
  List<TaxCalculation> _history = [];
  bool _loading = true;
  String _selectedPeriod = '';

  @override
  void initState() {
    super.initState();
    _selectedPeriod = DateFormat('yyyy-MM').format(DateTime.now());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final localData = await DataImportService.loadLocalData();
    double totalSales = 0;
    double totalExpenses = 0;
    if (localData != null) {
      totalSales = await DatabaseService.getTotalByType('income', '$_selectedPeriod-01', '$_selectedPeriod-31');
      totalExpenses = await DatabaseService.getTotalByType('expense', '$_selectedPeriod-01', '$_selectedPeriod-31');
    }
    final calc = TaxService.calculateTaxes(period: _selectedPeriod, totalSales: totalSales, totalExpenses: totalExpenses);
    final history = await TaxService.getHistory();
    setState(() { _currentCalc = calc; _history = history; _loading = false; });
  }

  Future<void> _saveCurrent() async {
    if (_currentCalc == null) return;
    await TaxService.saveCalculation(_currentCalc!);
    _loadData();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cálculo guardado')));
  }

  Future<void> _changePeriod() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
    if (picked != null) { setState(() { _selectedPeriod = DateFormat('yyyy-MM').format(picked); }); _loadData(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impuestos (ONAT)'), actions: [IconButton(icon: const Icon(Icons.calendar_today), onPressed: _changePeriod)]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Período: $_selectedPeriod', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_currentCalc != null) ...[
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Resumen de impuestos', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                Text('Ingresos brutos: \$${_currentCalc!.grossIncome.toStringAsFixed(2)}'),
                Text('Gastos: \$${_currentCalc!.expenses.toStringAsFixed(2)}'),
                Text('Base imponible: \$${_currentCalc!.taxableIncome.toStringAsFixed(2)}'),
                const Divider(),
                Text('IMPUESTO A PAGAR: \$${_currentCalc!.taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18)),
              ]))),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(onPressed: _saveCurrent, icon: const Icon(Icons.save), label: const Text('GUARDAR CÁLCULO'))),
            ],
            const SizedBox(height: 24),
            if (_history.isNotEmpty) ...[
              const Text('Historial', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(child: ListView.builder(itemCount: _history.length, itemBuilder: (_, i) {
                final h = _history[i];
                return ListTile(title: Text('Período: ${h.period}'), subtitle: Text('Ingresos: \$${h.grossIncome.toStringAsFixed(2)}'), trailing: Text('Impuesto: \$${h.taxAmount.toStringAsFixed(2)}'));
              })),
            ],
          ],
        ),
      ),
    );
  }
}