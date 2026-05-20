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

  // Valores reales (cargados de la base de datos)
  double _realGrossIncome = 0;
  double _realTotalExpenses = 0;

  // Valores reportados (el usuario los modifica)
  final _reportedIncomeCtrl = TextEditingController();
  final _reportedExpensesCtrl = TextEditingController();

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final period = _monthFormat.format(_selectedDate);
      final startDate = '$period-01';
      final endDate = '$period-31';
      _realGrossIncome = await DatabaseService.getTotalByType('income', startDate, endDate);
      _realTotalExpenses = await DatabaseService.getTotalByType('expense', startDate, endDate);

      // Inicializar los campos reportados con los valores reales
      _reportedIncomeCtrl.text = _realGrossIncome.toStringAsFixed(2);
      _reportedExpensesCtrl.text = _realTotalExpenses.toStringAsFixed(2);
    } catch (e) {
      _error = 'Error al cargar declaración.\n$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  /// Calcula el impuesto (5 % del neto positivo)
  double _calculateTax(double income, double expenses) {
    final net = income - expenses;
    return net > 0 ? net * 0.05 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final period = _monthFormat.format(_selectedDate);

    // Valores reales
    final realNetIncome = _realGrossIncome - _realTotalExpenses;
    final realTax = _calculateTax(_realGrossIncome, _realTotalExpenses);

    // Valores reportados
    final reportedIncome =
        double.tryParse(_reportedIncomeCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final reportedExpenses =
        double.tryParse(_reportedExpensesCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final reportedNet = reportedIncome - reportedExpenses;
    final reportedTax = _calculateTax(reportedIncome, reportedExpenses);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Declaración Jurada ONAT'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickMonth),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Período: $period',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),

                        // ─── SECCIÓN REAL ──────────────────────────────────
                        Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('📊 VALORES REALES (según registros)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const Divider(),
                                Text('Ingresos Brutos: \$${_realGrossIncome.toStringAsFixed(2)}'),
                                Text('Gastos Deducibles: \$${_realTotalExpenses.toStringAsFixed(2)}'),
                                const Divider(),
                                Text('Ingreso Neto: \$${realNetIncome.toStringAsFixed(2)}'),
                                const SizedBox(height: 8),
                                Text(
                                  'Impuesto (5 %): \$${realTax.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ─── SECCIÓN REPORTADA ────────────────────────────
                        Card(
                          color: Colors.orange.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('📝 VALORES A REPORTAR (ajústelos manualmente)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const Divider(),
                                TextField(
                                  controller: _reportedIncomeCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Ingresos a reportar',
                                    border: OutlineInputBorder(),
                                    prefixText: '\$ ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _reportedExpensesCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Gastos a reportar',
                                    border: OutlineInputBorder(),
                                    prefixText: '\$ ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                                const Divider(),
                                Text('Ingreso Neto reportado: \$${reportedNet.toStringAsFixed(2)}'),
                                const SizedBox(height: 8),
                                Text(
                                  'Impuesto a pagar (est.): \$${reportedTax.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => OnatAdvancedService.generateDj01(
                              period,
                              realIncome: _realGrossIncome,
                              realExpenses: _realTotalExpenses,
                              reportedIncome: reportedIncome,
                              reportedExpenses: reportedExpenses,
                            ),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Exportar Declaración (PDF)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}