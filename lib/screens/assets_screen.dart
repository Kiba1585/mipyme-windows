import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController(text: '5');
  List<Map<String, dynamic>> _assets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _loading = true);
    _assets = await DatabaseService.getFinancialRecords(type: 'asset');
    setState(() => _loading = false);
  }

  Future<void> _addAsset() async {
    if (!_formKey.currentState!.validate()) return;

    final value = double.tryParse(_valueCtrl.text) ?? 0;
    final years = int.tryParse(_yearsCtrl.text) ?? 5;
    final monthlyDepreciation = value / (years * 12);

    await DatabaseService.addFinancialRecord(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      type: 'asset',
      amount: value,
      category: 'Activo Fijo',
      description: '${_nameCtrl.text.trim()} | Depreciación mensual: \$${monthlyDepreciation.toStringAsFixed(2)} ($years años)',
    );

    _nameCtrl.clear();
    _valueCtrl.clear();
    _yearsCtrl.text = '5';

    _loadAssets();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activo registrado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activos Fijos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registrar activo fijo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del activo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _valueCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Valor de adquisición',
                            border: OutlineInputBorder(),
                            prefixText: '\$ ',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _yearsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Años de vida útil',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _addAsset,
                      icon: const Icon(Icons.add_business),
                      label: const Text('REGISTRAR ACTIVO'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Activos registrados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _assets.isEmpty
                    ? const Text('No hay activos registrados')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _assets.length,
                        itemBuilder: (_, i) {
                          final asset = _assets[i];
                          return Card(
                            child: ListTile(
                              title: Text(asset['description'] ?? 'Activo ${i + 1}'),
                              subtitle: Text(
                                'Valor: \$${(asset['amount'] as num).toStringAsFixed(2)} | ${asset['date']}',
                              ),
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