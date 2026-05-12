import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  String _status = '';

  Future<void> _exportSyncFile() async {
    try {
      final jsonString = await SyncService.exportToJson();
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo de sincronización',
        fileName: 'mipyme_sync.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path == null) return;
      await File(path).writeAsString(jsonString);
      setState(() => _status = 'Archivo de sincronización exportado correctamente.');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _importSyncFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      await SyncService.importFromJson(jsonString);
      setState(() => _status = 'Datos importados correctamente.');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronizar con Móvil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _exportSyncFile,
                icon: const Icon(Icons.upload),
                label: const Text('Exportar datos (para móvil)'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _importSyncFile,
                icon: const Icon(Icons.download),
                label: const Text('Importar datos (desde móvil)'),
              ),
            ),
            const SizedBox(height: 24),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.green.shade50,
                child: Text(_status),
              ),
          ],
        ),
      ),
    );
  }
}