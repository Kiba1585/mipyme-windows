import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/inventory_export_service.dart';

class BulkInventoryScreen extends StatefulWidget {
  const BulkInventoryScreen({super.key});

  @override
  State<BulkInventoryScreen> createState() => _BulkInventoryScreenState();
}

class _BulkInventoryScreenState extends State<BulkInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _products = [];
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'unidad');

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _addProduct() {
    if (!_formKey.currentState!.validate()) return;
    _products.add({
      'product_code': _codeCtrl.text.trim(),
      'name': _nameCtrl.text.trim(),
      'category': _categoryCtrl.text.trim(),
      'price': double.parse(_priceCtrl.text.trim()),
      'cost': _costCtrl.text.isEmpty ? null : double.parse(_costCtrl.text.trim()),
      'stock': double.parse(_stockCtrl.text.trim()),
      'unit': _unitCtrl.text.trim(),
    });
    _codeCtrl.clear();
    _nameCtrl.clear();
    _categoryCtrl.clear();
    _priceCtrl.clear();
    _costCtrl.clear();
    _stockCtrl.clear();
    _unitCtrl.text = 'unidad';
    setState(() {});
  }

  void _removeProduct(int index) {
    _products.removeAt(index);
    setState(() {});
  }

  Future<void> _exportToMobile() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregue al menos un producto')),
      );
      return;
    }
    try {
      final path = await InventoryExportService.exportInventoryForMobile(_products);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archivo de inventario exportado a: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carga masiva de inventario')),
      body: Column(
        children: [
          // Formulario
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(labelText: 'Código', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _categoryCtrl,
                    decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          decoration: const InputDecoration(labelText: 'Precio', border: OutlineInputBorder(), prefixText: '\$ '),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _costCtrl,
                          decoration: const InputDecoration(labelText: 'Costo', border: OutlineInputBorder(), prefixText: '\$ '),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockCtrl,
                          decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _unitCtrl,
                          decoration: const InputDecoration(labelText: 'Unidad', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _addProduct,
                      icon: const Icon(Icons.add),
                      label: const Text('AGREGAR PRODUCTO'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de productos agregados
          Expanded(
            child: _products.isEmpty
                ? const Center(child: Text('No hay productos en la lista'))
                : ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (_, i) {
                      final product = _products[i];
                      return ListTile(
                        title: Text(product['name'] as String),
                        subtitle: Text('Código: ${product['product_code']} | Stock: ${product['stock']} ${product['unit']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeProduct(i),
                        ),
                      );
                    },
                  ),
          ),

          // Botón exportar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _products.isEmpty ? null : _exportToMobile,
                  icon: const Icon(Icons.file_download),
                  label: Text('EXPORTAR PARA MÓVIL (${_products.length} productos)'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}