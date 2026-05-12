import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';

class WindowsBackupService {
  static const String backupFileName = 'mipyme_windows_backup.db';

  /// Obtiene la ruta de la base de datos actual
  static Future<String> _getCurrentDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/mipyme_windows.db';
  }

  /// Exporta la base de datos a un archivo seleccionado por el usuario
  static Future<String> exportBackup() async {
    // Primero intentar con saveFile
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Seleccione dónde guardar la copia de seguridad',
        fileName: 'mipyme_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db',
        type: FileType.any,
      );
      if (path != null) {
        final outputFile = File(path.endsWith('.db') ? path : '$path.db');
        await File(await _getCurrentDbPath()).copy(outputFile.path);
        return outputFile.path;
      }
    } catch (_) {
      // Si saveFile no funciona, usar getDirectoryPath
    }

    // Fallback: elegir carpeta
    final dirPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Seleccione la carpeta donde guardar la copia',
    );
    if (dirPath == null) throw Exception('No se seleccionó ninguna carpeta');

    final dir = Directory(dirPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    final backupFile = File('$dirPath/$backupFileName');
    await File(await _getCurrentDbPath()).copy(backupFile.path);
    return backupFile.path;
  }

  /// Importa una base de datos desde un archivo seleccionado por el usuario
  static Future<void> importBackup(BuildContext context) async {
    // Mostrar confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar copia de seguridad'),
        content: const Text(
          'Se reemplazarán todos los datos actuales. ¿Está seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Importar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final selectedPath = result.files.single.path;
    if (selectedPath == null) throw Exception('Archivo no válido');

    final selectedFile = File(selectedPath);
    if (!await selectedFile.exists()) throw Exception('El archivo no existe');

    final currentPath = await _getCurrentDbPath();
    await selectedFile.copy(currentPath);

    // Mostrar éxito
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Base de datos restaurada correctamente. Reinicie la aplicación.')),
      );
    }
  }

  /// Muestra un diálogo de éxito después de exportar
  static Future<void> showSuccessDialog(BuildContext context, String path) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Copia de seguridad creada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('La copia se guardó correctamente en:'),
            const SizedBox(height: 8),
            SelectableText(path, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Share.shareXFiles([XFile(path)], text: 'Copia de seguridad MIPYME Windows');
            },
            child: const Text('Compartir'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}