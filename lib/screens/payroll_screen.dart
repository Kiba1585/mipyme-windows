import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _bonusCtrl = TextEditingController(text: '0');
  final _deductionsCtrl = TextEditingController(text: '0');
  List<Map<String, dynamic>> _payrollHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    _payrollHistory = await DatabaseService.getFinancialRecords(
      type: 'payroll',
    );
    setState(() => _loading = false);
  }

  Future<void> _addPayroll() async {
    if (!_formKey.currentState!.validate()) return;

    final salary = double.tryParse(_salaryCtrl.text) ?? 0;
    final bonus = double.tryParse(_bonusCtrl.text) ?? 0;
    final deductions = double.tryParse(_deductionsCtrl.text) ?? 0;
    final total = salary + bonus - deductions;

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El total a pagar debe ser mayor que 0')),
      );
      return;
    }

    await DatabaseService.addFinancialRecord(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      type: 'payroll',
      amount: total,
      category: 'Nómina',
      description: '${_nameCtrl.text.trim()}: Salario \$$salary + Bono \$$bonus - Deduc. \$$deductions',
    );

    _nameCtrl.clear();
    _salaryCtrl.clear();
    _bonusCtrl.text = '0';
    _deductionsCtrl.text = '0';

    _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago registrado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nóminas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registrar pago a trabajador',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del trabajador',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _salaryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Salario base',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bonusCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Bonos',
                            border: OutlineInputBorder(),
                            prefixText: '\$ ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _deductionsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Deducciones',
                            border: OutlineInputBorder(),
                            prefixText: '\$ ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _addPayroll,
                      icon: const Icon(Icons.payment),
                      label: const Text('REGISTRAR PAGO'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Historial de pagos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _payrollHistory.isEmpty
                    ? const Text('No hay pagos registrados')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _payrollHistory.length,
                        itemBuilder: (_, i) {
                          final record = _payrollHistory[i];
                          return Card(
                            child: ListTile(
                              title: Text(
                                (record['amount'] as num).toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(record['description'] ?? ''),
                              trailing: Text(record['date'] as String),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}