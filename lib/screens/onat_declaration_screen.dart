import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/onat_advanced_service.dart';
import '../services/database_service.dart';

class OnatDeclarationScreen extends StatefulWidget {
  const OnatDeclarationScreen({super.key});

  @override
  State<OnatDeclarationScreen> createState() => _OnatDeclarationScreenState();
}

class _OnatDeclarationScreenState extends State<OnatDeclarationScreen> {
  final DateFormat _monthFormat = DateFormat('yyyy-MM');
  DateTime _selectedDate = DateTime.now();
  double _grossIncome = 0;
  double _totalExpenses = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final period = _monthFormat.format(_selectedDate);
    final startDate = '$period-01';
    final endDate = '$period-31';
    _grossIncome = await DatabaseService.getTotalByType('income', startDate, endDate);
    _totalExpenses = await DatabaseService.getTotalByType('expense', startDate, endDate);
    setState(() => _loading = false);
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
    final period = _monthFormat.format(_selectedDate);
    final netIncome = _grossIncome - _totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Declaración Jurada ONAT'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickMonth),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Período: $period',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ingresos Brutos: \$${_grossIncome.toStringAsFixed(2)}'),
                          Text('Gastos Deducibles: \$${_totalExpenses.toStringAsFixed(2)}'),
                          const Divider(),
                          Text('Ingreso Neto: \$${netIncome.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          Text(
                            'Impuesto a Pagar (est.): \$${(netIncome > 0 ? netIncome * 0.05 : 0).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => OnatAdvancedService.generateDj01(period),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar Declaración (PDF)'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
