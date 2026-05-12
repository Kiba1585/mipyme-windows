import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class FinancialRecordsScreen extends StatefulWidget {
  const FinancialRecordsScreen({super.key});
  @override
  State<FinancialRecordsScreen> createState() => _FinancialRecordsScreenState();
}

class _FinancialRecordsScreenState extends State<FinancialRecordsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'expense';
  String _category = 'General';
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  final _categories = ['General', 'Transporte', 'Trabajadores', 'Local', 'Insumos', 'Impuesto'];

  @override
  void initState() { super.initState(); _loadRecords(); }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    _records = await DatabaseService.getFinancialRecords();
    setState(() => _loading = false);
  }

  Future<void> _addRecord() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un monto válido')));
      return;
    }
    await DatabaseService.addFinancialRecord(date: DateFormat('yyyy-MM-dd').format(DateTime.now()), type: _type, amount: amount, category: _category, description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null);
    _amountCtrl.clear(); _descCtrl.clear();
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registros financieros')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(children: [
                    Expanded(flex: 2, child: TextFormField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Monto', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null)),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'expense', child: Text('Gasto')), DropdownMenuItem(value: 'income', child: Text('Ingreso'))], onChanged: (v) => setState(() => _type = v!))),
                  ]),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(value: _category, decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()), items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _category = v!)),
                  const SizedBox(height: 8),
                  TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(onPressed: _addRecord, icon: const Icon(Icons.add), label: const Text('AGREGAR'))),
                ],
              ),
            ),
          ),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _records.isEmpty ? const Center(child: Text('Sin registros')) : ListView.builder(itemCount: _records.length, itemBuilder: (_, i) {
            final r = _records[i];
            return ListTile(title: Text('${r['category']} - \$${(r['amount'] as num).toStringAsFixed(2)}'), subtitle: Text('${r['date']} · ${r['type']}'), trailing: Icon(r['type'] == 'income' ? Icons.arrow_upward : Icons.arrow_downward, color: r['type'] == 'income' ? Colors.green : Colors.red));
          })),
        ],
      ),
    );
  }
}