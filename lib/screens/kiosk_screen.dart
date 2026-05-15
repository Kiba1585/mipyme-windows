import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/audit_service.dart';

class KioskScreen extends StatefulWidget {
  final VoidCallback onExit;
  const KioskScreen({super.key, required this.onExit});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'income';
  String _category = 'General';
  double _todayIncome = 0;
  double _todayExpenses = 0;
  bool _loading = true;

  final _categories = ['General', 'Transporte', 'Trabajadores', 'Local', 'Insumos', 'Impuesto'];

  @override
  void initState() {
    super.initState();
    _loadTodaySummary();
  }

  Future<void> _loadTodaySummary() async {
    setState(() => _loading = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _todayIncome = await DatabaseService.getTotalByType('income', today, today);
    _todayExpenses = await DatabaseService.getTotalByType('expense', today, today);
    setState(() => _loading = false);
  }

  Future<void> _addRecord() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un monto válido')),
      );
      return;
    }
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await DatabaseService.addFinancialRecord(
      date: date,
      type: _type,
      amount: amount,
      category: _category,
      description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
    );
    await AuditService.log(
      'Registro desde modo quiosco',
      details: 'Monto: \$${amount.toStringAsFixed(2)}, Categoría: $_category, Tipo: $_type',
    );
    _amountCtrl.clear();
    _descCtrl.clear();
    _loadTodaySummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro rápido'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Salir del modo quiosco',
            onPressed: widget.onExit,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Resumen del día
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Ingresos', _todayIncome, Colors.green),
                    _buildSummaryItem('Gastos', _todayExpenses, Colors.red),
                    _buildSummaryItem('Balance', _todayIncome - _todayExpenses, Colors.blue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Formulario rápido
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'income', child: Text('Ingreso')),
                      DropdownMenuItem(value: 'expense', child: Text('Gasto')),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _addRecord,
                icon: const Icon(Icons.add),
                label: const Text('REGISTRAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}