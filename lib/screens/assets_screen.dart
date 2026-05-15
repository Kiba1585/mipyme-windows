import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
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
  List<Asset> _assets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _assets = await DatabaseService.getAssets();
    } catch (e) {
      _error = 'No se pudieron cargar los activos.\n$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addAsset() async {
    if (!_formKey.currentState!.validate()) return;

    final value = double.tryParse(_valueCtrl.text) ?? 0;
    final years = int.tryParse(_yearsCtrl.text) ?? 5;
    final acquisitionDate = DateTime.now();

    final asset = Asset(
      name: _nameCtrl.text.trim(),
      value: value,
      usefulLifeYears: years,
      acquisitionDate: acquisitionDate,
    );

    await DatabaseService.addAsset(asset);
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

  Future<void> _deleteAsset(int id) async {
    await DatabaseService.deleteAsset(id);
    _loadAssets();
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
                : _error != null
                    ? _buildError()
                    : _assets.isEmpty
                        ? const Text('No hay activos registrados')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _assets.length,
                            itemBuilder: (_, i) {
                              final asset = _assets[i];
                              final monthsSinceAcquisition = DateTime.now()
                                      .difference(asset.acquisitionDate)
                                      .inDays ~/ 30;
                              final accumulatedDepreciation =
                                  asset.monthlyDepreciation * monthsSinceAcquisition;
                              final currentValue = asset.value - accumulatedDepreciation;

                              return Card(
                                child: ListTile(
                                  title: Text(asset.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Valor original: \$${asset.value.toStringAsFixed(2)}'),
                                      Text('Depreciación mensual: \$${asset.monthlyDepreciation.toStringAsFixed(2)}'),
                                      Text('Depreciación acumulada: \$${accumulatedDepreciation.toStringAsFixed(2)}'),
                                      Text(
                                        'Valor actual: \$${currentValue.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                          'Adquirido: ${DateFormat('dd/MM/yyyy').format(asset.acquisitionDate)}'),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteAsset(asset.id!),
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
            onPressed: _loadAssets,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}