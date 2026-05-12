import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../services/database_service.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _productsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  List<Supplier> _suppliers = [];
  bool _loading = true;
  Supplier? _editingSupplier;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers({String? search}) async {
    setState(() => _loading = true);
    final suppliers = await DatabaseService.getSuppliers(search: search);
    setState(() {
      _suppliers = suppliers;
      _loading = false;
    });
  }

  void _clearForm() {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _productsCtrl.clear();
    _notesCtrl.clear();
    setState(() => _editingSupplier = null);
  }

  void _editSupplier(Supplier supplier) {
    _nameCtrl.text = supplier.name;
    _phoneCtrl.text = supplier.phone ?? '';
    _productsCtrl.text = supplier.products ?? '';
    _notesCtrl.text = supplier.notes ?? '';
    setState(() => _editingSupplier = supplier);
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;
    final supplier = Supplier(
      id: _editingSupplier?.id,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      products: _productsCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    if (_editingSupplier != null) {
      await DatabaseService.updateSupplier(supplier);
    } else {
      await DatabaseService.addSupplier(supplier);
    }
    _clearForm();
    _loadSuppliers();
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar proveedor'),
        content: Text('¿Eliminar a ${supplier.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true && supplier.id != null) {
      await DatabaseService.deleteSupplier(supplier.id!);
      _loadSuppliers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proveedores')),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar proveedor',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _loadSuppliers(search: value),
            ),
          ),

          // Formulario
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _productsCtrl,
                    decoration: const InputDecoration(labelText: 'Productos que ofrece', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveSupplier,
                          icon: Icon(_editingSupplier != null ? Icons.save : Icons.add),
                          label: Text(_editingSupplier != null ? 'Guardar cambios' : 'Agregar proveedor'),
                        ),
                      ),
                      if (_editingSupplier != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _clearForm,
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lista de proveedores
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _suppliers.isEmpty
                    ? const Center(child: Text('No hay proveedores registrados'))
                    : ListView.builder(
                        itemCount: _suppliers.length,
                        itemBuilder: (_, i) {
                          final supplier = _suppliers[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(supplier.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (supplier.phone != null) Text(supplier.phone!),
                                  if (supplier.products != null) Text(supplier.products!),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _editSupplier(supplier),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _deleteSupplier(supplier),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
