import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../services/database_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final DateFormat _monthFormat = DateFormat('yyyy-MM');
  DateTime _selectedDate = DateTime.now();
  final _incomeCtrl = TextEditingController();
  final _expensesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  Budget? _budget;
  double _realIncome = 0;
  double _realExpenses = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    setState(() => _loading = true);
    final month = _monthFormat.format(_selectedDate);
    _budget = await DatabaseService.getBudget(month);
    if (_budget != null) {
      _incomeCtrl.text = _budget!.projectedIncome.toString();
      _expensesCtrl.text = _budget!.projectedExpenses.toString();
      _notesCtrl.text = _budget!.notes ?? '';
    } else {
      _incomeCtrl.clear();
      _expensesCtrl.clear();
      _notesCtrl.clear();
    }
    // Datos reales del mes
    final startDate = '$month-01';
    final endDate = '$month-31';
    _realIncome = await DatabaseService.getTotalByType('income', startDate, endDate);
    _realExpenses = await DatabaseService.getTotalByType('expense', startDate, endDate);
    setState(() => _loading = false);
  }

  Future<void> _saveBudget() async {
    final month = _monthFormat.format(_selectedDate);
    final income = double.tryParse(_incomeCtrl.text) ?? 0;
    final expenses = double.tryParse(_expensesCtrl.text) ?? 0;
    final budget = Budget(
      id: _budget?.id,
      month: month,
      projectedIncome: income,
      projectedExpenses: expenses,
      notes: _notesCtrl.text,
    );
    await DatabaseService.saveBudget(budget);
    _loadBudget();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presupuesto guardado')),
      );
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadBudget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = _monthFormat.format(_selectedDate);
    final netProjected = (_budget?.projectedIncome ?? 0) - (_budget?.projectedExpenses ?? 0);
    final netReal = _realIncome - _realExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto Mensual'),
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
                  Text('Mes: $month',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _incomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ingresos proyectados',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _expensesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Gastos proyectados',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saveBudget,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar presupuesto'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Comparativa con la realidad',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildCompareRow('Ingresos', _budget?.projectedIncome ?? 0, _realIncome),
                          _buildCompareRow('Gastos', _budget?.projectedExpenses ?? 0, _realExpenses),
                          const Divider(),
                          _buildCompareRow('Neto', netProjected, netReal),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCompareRow(String label, double projected, double real) {
    final diff = real - projected;
    final color = diff >= 0 ? Colors.green : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label)),
          Expanded(flex: 4, child: Text('Proy: \$${projected.toStringAsFixed(2)}')),
          Expanded(flex: 4, child: Text('Real: \$${real.toStringAsFixed(2)}')),
          Expanded(
            flex: 3,
            child: Text(
              '${diff >= 0 ? '+' : ''}\$${diff.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
