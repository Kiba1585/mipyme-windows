import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../services/database_service.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final _nameCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _bonusCtrl = TextEditingController(text: '0');
  final _deductionCtrl = TextEditingController(text: '0');
  final _searchCtrl = TextEditingController();
  List<Employee> _employees = [];
  List<Map<String, dynamic>> _payrollHistory = [];
  Employee? _selectedEmployee;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _employees = await DatabaseService.getEmployees(search: _searchCtrl.text);
    _payrollHistory = await DatabaseService.getFinancialRecords(type: 'payroll');
    setState(() => _loading = false);
  }

  Future<void> _addEmployee() async {
    if (_nameCtrl.text.isEmpty || _salaryCtrl.text.isEmpty) return;
    await DatabaseService.addEmployee(Employee(name: _nameCtrl.text.trim(), baseSalary: double.parse(_salaryCtrl.text)));
    _nameCtrl.clear(); _salaryCtrl.clear();
    _load();
  }

  Future<void> _payEmployee(Employee emp) async {
    final bonus = double.tryParse(_bonusCtrl.text) ?? 0;
    final deduction = double.tryParse(_deductionCtrl.text) ?? 0;
    final total = emp.baseSalary + bonus - deduction;
    await DatabaseService.addFinancialRecord(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      type: 'payroll', amount: total, category: 'Nómina',
      description: '${emp.name}: Base \$${emp.baseSalary} + Bono \$${bonus} - Deduc. \$${deduction}',
    );
    _bonusCtrl.text = '0'; _deductionCtrl.text = '0';
    _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago registrado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nóminas')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Registrar empleado
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre empleado', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _salaryCtrl, decoration: const InputDecoration(labelText: 'Salario base', border: OutlineInputBorder(), prefixText: '\$ '), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _addEmployee, icon: const Icon(Icons.person_add), label: const Text('Agregar empleado')),
            const SizedBox(height: 24),
            // Buscar y pagar
            TextField(controller: _searchCtrl, decoration: const InputDecoration(labelText: 'Buscar empleado', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (_) => _load()),
            const SizedBox(height: 12),
            ..._employees.map((emp) => Card(
              child: ListTile(
                title: Text(emp.name),
                subtitle: Text('Base: \$${emp.baseSalary.toStringAsFixed(2)}'),
                trailing: ElevatedButton(onPressed: () => _payEmployee(emp), child: const Text('Pagar')),
              ),
            )),
            if (_employees.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextField(controller: _bonusCtrl, decoration: const InputDecoration(labelText: 'Bono extra', border: OutlineInputBorder(), prefixText: '\$ '), keyboardType: TextInputType.number),
              TextField(controller: _deductionCtrl, decoration: const InputDecoration(labelText: 'Deducciones', border: OutlineInputBorder(), prefixText: '\$ '), keyboardType: TextInputType.number),
            ],
            const SizedBox(height: 24),
            const Text('Historial de pagos', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._payrollHistory.map((r) => ListTile(title: Text('\$${(r['amount'] as num).toStringAsFixed(2)}'), subtitle: Text('${r['description']}  |  ${r['date']}'))),
          ],
        ),
      ),
    );
  }
}
