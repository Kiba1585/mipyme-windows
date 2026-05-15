import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'database_service.dart';

class WindowsBackupService {
  static const String backupFileName = 'mipyme_windows_backup.db';

  static Future<String> _getCurrentDbPath() async {
    final db = await DatabaseService.database;
    return db.path;
  }

  static Future<String> exportBackup() async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar copia de seguridad',
        fileName: 'mipyme_backup.db',
        type: FileType.any,
      );
      if (path != null) {
        final outputFile = File(path.endsWith('.db') ? path : '$path.db');
        await File(await _getCurrentDbPath()).copy(outputFile.path);
        return outputFile.path;
      }
    } catch (_) {}

    final dirPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Seleccione carpeta',
    );
    if (dirPath == null) throw Exception('No se seleccionó carpeta');

    final dir = Directory(dirPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    final backupFile = File('$dirPath/$backupFileName');
    await File(await _getCurrentDbPath()).copy(backupFile.path);
    return backupFile.path;
  }

  static Future<void> importBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar copia'),
        content: const Text('Se reemplazarán todos los datos. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importar')),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final selectedPath = result.files.single.path;
    if (selectedPath == null) throw Exception('Archivo no válido');

    final selectedFile = File(selectedPath);
    if (!await selectedFile.exists()) throw Exception('El archivo no existe');

    final currentPath = await _getCurrentDbPath();
    await selectedFile.copy(currentPath);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Base restaurada. Reinicie la aplicación.')),
      );
    }
  }

  static Future<void> showSuccessDialog(BuildContext context, String path) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Copia creada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guardada en:'),
            const SizedBox(height: 8),
            SelectableText(path, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Share.shareXFiles([XFile(path)], text: 'Copia de seguridad MIPYME');
            },
            child: const Text('Compartir'),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Aceptar')),
        ],
      ),
    );
  }
}