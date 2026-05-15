import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../services/data_import_service.dart';
import '../services/audit_service.dart';
import '../core/theme/theme_scope.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _status;

  Future<void> _import([String? filePath]) async {
    setState(() {
      _loading = true;
      _status = filePath != null ? 'Importando archivo arrastrado...' : 'Abriendo archivo...';
    });

    // Si se arrastró un archivo, usarlo directamente; si no, abrir el diálogo
    final data = filePath != null
        ? await DataImportService.importMipymeFileFromPath(filePath)
        : await DataImportService.importMipymeFile();

    if (data == null) {
      setState(() {
        _status = 'No se pudo importar el archivo. Formato incorrecto o licencia no coincide.';
        _loading = false;
      });
      return;
    }

    await DataImportService.saveLocalData(data);
    await AuditService.log('Datos importados desde .mipyme', details: 'Archivo importado correctamente');

    if (data.containsKey('theme_preference')) {
      final isDark = data['theme_preference'] == 'dark';
      ThemeScope.of(context)?.onThemeChanged(isDark);
    }

    setState(() {
      _data = data;
      _status = 'Archivo importado correctamente.';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar datos')),
      body: DropTarget(
        onDragDone: (detail) {
          final file = detail.files.firstOrNull;
          if (file != null && file.path.endsWith('.mipyme')) {
            _import(file.path);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : () => _import(),
                  icon: const Icon(Icons.file_open),
                  label: const Text('Seleccionar archivo .mipyme'),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: const Column(
                  children: [
                    Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('O arrastre y suelte aquí un archivo .mipyme'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_status != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: _data != null ? Colors.green.shade50 : Colors.orange.shade50,
                  child: Text(_status!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}