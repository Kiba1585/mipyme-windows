import 'package:flutter/material.dart';
import '../services/data_import_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _status;

  Future<void> _import() async {
    setState(() {
      _loading = true;
      _status = 'Abriendo archivo...';
    });

    final data = await DataImportService.importMipymeFile();
    if (data == null) {
      setState(() {
        _status = 'No se seleccionó ningún archivo o el formato es incorrecto.';
        _loading = false;
      });
      return;
    }

    await DataImportService.saveLocalData(data);
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _import,
                icon: const Icon(Icons.file_open),
                label: const Text('Seleccionar archivo .mipyme'),
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
    );
  }
}